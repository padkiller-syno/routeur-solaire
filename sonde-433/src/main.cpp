// Sonde déportée du ballon : mesure l'eau toutes les ~60 s et l'envoie en 433 MHz au routeur (ESPHome,
// remote_receiver + on_rc_switch). Arduino Pro Mini alimenté directement par la 18650 (broche VCC), DS18B20
// alimentée par une broche (coupée en veille), émetteur STX882.
//
// Trame de 32 bits, protocole 1 de rc-switch (impulsion 350 µs ; 0 = 1 haut / 3 bas, 1 = 3 haut / 1 bas,
// synchro = 1 haut / 31 bas), envoyée 5 fois de suite :
//   bits 31-28 : identifiant de la sonde (0xA)
//   bits 27-17 : température (°C + 20) × 10, 0 à 2046 ; 2047 = sonde en défaut
//   bits 16-10 : tension de la batterie (mV − 2000) / 20, soit 2,00 à 4,54 V
//   bits  9-8  : compteur de trame (le routeur ignore les répétitions)
//   bits  7-0  : CRC-8 (polynôme 0x07) des 24 bits du dessus
#include <Arduino.h>
#include <OneWire.h>
#include <avr/power.h>
#include <avr/sleep.h>
#include <avr/wdt.h>

constexpr uint8_t PIN_TX = 2;       // DATA du STX882
constexpr uint8_t PIN_DS = 3;       // DAT de la sonde (tirage 4,7 kΩ de l'adaptateur vers PIN_DS_VCC)
constexpr uint8_t PIN_DS_VCC = 4;   // VCC de la sonde : alimentée seulement pendant la mesure
constexpr uint8_t PIN_LED = 13;

constexpr uint8_t ID_SONDE = 0xA;
constexpr uint8_t CYCLES_8S = 7;          // 7 × 8 s + mesure ≈ 60 s entre deux envois
constexpr uint8_t CYCLES_8S_FAIBLE = 75;  // batterie presque vide : un envoi toutes les ~10 min
constexpr uint16_t VCC_FAIBLE_MV = 3100;
constexpr uint16_t IMPULSION_US = 350;
constexpr uint8_t REPETITIONS = 5;

// Tension de la référence interne × 1023 × 1000. Nominale 1,1 V (±10 %) : à corriger avec un multimètre
// (VREF_CAL = 1125300 × tension mesurée / tension affichée par le routeur).
constexpr uint32_t VREF_CAL = 1125300UL;

OneWire ds(PIN_DS);
uint8_t compteur = 0;

ISR(WDT_vect) {}

// Veille la plus profonde (power-down), réveil par le chien de garde.
static void dormir(uint8_t wdto) {
  cli();
  wdt_reset();
  MCUSR &= ~_BV(WDRF);
  WDTCSR = _BV(WDCE) | _BV(WDE);
  WDTCSR = _BV(WDIE) | ((wdto & 0x08) ? _BV(WDP3) : 0) | (wdto & 0x07);
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);
  sleep_enable();
  sleep_bod_disable();  // détecteur de sous-tension coupé pendant le sommeil (ATmega328P)
  sei();
  sleep_cpu();
  sleep_disable();
  wdt_disable();
}

// Tension d'alimentation (= batterie) mesurée contre la référence interne de 1,1 V.
static uint16_t lire_vcc_mv() {
  power_adc_enable();
  ADCSRA |= _BV(ADEN);
  ADMUX = _BV(REFS0) | _BV(MUX3) | _BV(MUX2) | _BV(MUX1);
  delay(2);
  for (uint8_t i = 0; i < 2; i++) {  // la première conversion après changement de référence est fausse
    ADCSRA |= _BV(ADSC);
    while (bit_is_set(ADCSRA, ADSC)) {
    }
  }
  const uint16_t adc = ADC;
  ADCSRA &= ~_BV(ADEN);
  power_adc_disable();
  return adc ? VREF_CAL / adc : 0;
}

static void couper_sonde() {
  pinMode(PIN_DS, INPUT);
  digitalWrite(PIN_DS, LOW);
  digitalWrite(PIN_DS_VCC, LOW);
}

// Température en °C, NAN si la sonde ne répond pas ou si la lecture est fausse.
static float lire_temperature() {
  pinMode(PIN_DS_VCC, OUTPUT);
  digitalWrite(PIN_DS_VCC, HIGH);
  delay(5);
  if (!ds.reset()) {
    couper_sonde();
    return NAN;
  }
  ds.skip();
  ds.write(0x4E);  // résolution 11 bits (0,125 °C, 375 ms) : la sonde repart en 12 bits à chaque mise sous tension
  ds.write(0x00);
  ds.write(0x00);
  ds.write(0x5F);
  ds.reset();
  ds.skip();
  ds.write(0x44);  // lancer la conversion
  dormir(WDTO_500MS);
  ds.reset();
  ds.skip();
  ds.write(0xBE);  // lire la mémoire
  uint8_t d[9];
  for (uint8_t i = 0; i < 9; i++) d[i] = ds.read();
  couper_sonde();
  if (OneWire::crc8(d, 8) != d[8]) return NAN;
  const int16_t brut = (int16_t)((d[1] << 8) | d[0]);
  if (brut == 0x0550) return NAN;  // 85 °C = valeur de mise sous tension, conversion non faite
  return brut / 16.0f;
}

static uint8_t crc8(uint32_t v) {
  uint8_t crc = 0;
  for (int8_t octet = 2; octet >= 0; octet--) {
    crc ^= (uint8_t)(v >> (8 * octet));
    for (uint8_t i = 0; i < 8; i++) crc = (crc & 0x80) ? (uint8_t)((crc << 1) ^ 0x07) : (uint8_t)(crc << 1);
  }
  return crc;
}

static uint32_t construire_trame(float t, uint16_t mv) {
  const uint16_t tc = isnan(t) ? 0x7FF : (uint16_t)constrain(lroundf((t + 20.0f) * 10.0f), 0L, 0x7FEL);
  const uint8_t bc = (uint8_t)constrain(((int16_t)mv - 2000) / 20, 0, 127);
  const uint32_t haut = ((uint32_t)ID_SONDE << 20) | ((uint32_t)tc << 9) | ((uint32_t)bc << 2) | (compteur & 3);
  return (haut << 8) | crc8(haut);
}

static inline void impulsion(uint8_t haut, uint8_t bas) {
  digitalWrite(PIN_TX, HIGH);
  delayMicroseconds(IMPULSION_US * haut);
  digitalWrite(PIN_TX, LOW);
  delayMicroseconds(IMPULSION_US * bas);
}

static void emettre(uint32_t trame) {
  for (uint8_t r = 0; r < REPETITIONS; r++) {
    impulsion(1, 31);
    for (int8_t b = 31; b >= 0; b--) {
      if (trame & (1UL << b)) impulsion(3, 1);
      else impulsion(1, 3);
    }
  }
  impulsion(1, 31);
}

void setup() {
#ifdef QUARTZ_16MHZ
  clock_prescale_set(clock_div_2);
#endif
  // broches inutilisées en entrée avec tirage : pas d'entrée flottante qui consomme
  for (uint8_t p = 0; p <= A5; p++) pinMode(p, INPUT_PULLUP);
  pinMode(PIN_TX, OUTPUT);
  digitalWrite(PIN_TX, LOW);
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, LOW);
  pinMode(PIN_DS_VCC, OUTPUT);
  couper_sonde();
  power_adc_disable();
  power_spi_disable();
  power_twi_disable();
  power_timer1_disable();
  power_timer2_disable();
#ifdef DEBUG
  Serial.begin(57600);
#else
  power_usart0_disable();
#endif
}

void loop() {
  const float t = lire_temperature();
  const uint16_t mv = lire_vcc_mv();
  const uint32_t trame = construire_trame(t, mv);
#ifdef DEBUG
  Serial.print(F("T=")); Serial.print(t); Serial.print(F(" Vcc=")); Serial.print(mv);
  Serial.print(F(" trame=0x")); Serial.println(trame, HEX);
  Serial.flush();
#endif
  emettre(trame);
  compteur++;
  const uint8_t cycles = mv < VCC_FAIBLE_MV ? CYCLES_8S_FAIBLE : CYCLES_8S;
  for (uint8_t i = 0; i < cycles; i++) dormir(WDTO_8S);
}
