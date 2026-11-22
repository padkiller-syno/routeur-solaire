/* Test hors carte de routeur.h : gcc -Wall -Wextra -o /tmp/t test_routeur.c && /tmp/t */
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "../esphome/routeur-solaire/routeur.h"

static int echecs = 0;
#define VERIF(c) do { if (!(c)) { printf("ÉCHEC ligne %d : %s\n", __LINE__, #c); echecs++; } } while (0)

static void put32(uint8_t *p, uint32_t v) { p[0] = v >> 24; p[1] = v >> 16; p[2] = v >> 8; p[3] = v; }

int main(void) {
  /* CRC de la requête codée en dur dans la v9.15 */
  uint16_t c = modbus_crc16(JSY_REQUETE, 6);
  VERIF(JSY_REQUETE[6] == (c & 0xFF) && JSY_REQUETE[7] == (c >> 8));

  /* CRC de la trame de passage à 38 400 bauds (celle de vitesse_port_jsy.ino) */
  c = modbus_crc16(JSY_TRAME_38400, 9);
  VERIF(JSY_TRAME_38400[9] == (c & 0xFF) && JSY_TRAME_38400[10] == (c >> 8));

  /* Trame construite à la main */
  uint8_t t[JSY_TRAME_LEN] = {0x01, 0x03, 56};
  put32(t + 3, 2301234);     /* 230.1234 V */
  put32(t + 7, 52000);       /* 5.2 A */
  put32(t + 11, 11965000);   /* 1196.5 W -> 1196 */
  put32(t + 15, 1234567);    /* 123.4567 kWh */
  t[27] = 0; t[28] = 1;      /* canal 2 en injection */
  put32(t + 31, 5001);       /* 50.01 Hz */
  put32(t + 39, 21000);
  put32(t + 43, 4500000);    /* 450 W */
  put32(t + 47, 98765);
  put32(t + 55, 4321000);
  c = modbus_crc16(t, JSY_TRAME_LEN - 2);
  t[59] = c & 0xFF; t[60] = c >> 8;

  JsyMesure m;
  VERIF(jsy_decode(t, sizeof t, &m) == JSY_OK);
  VERIF(fabsf(m.tension - 230.1234f) < 0.001f);
  VERIF(m.puissance1 == 1196);
  VERIF(fabsf(m.energie1 - 123.4567f) < 0.001f);
  VERIF(m.sens2 == 1 && m.puissance2 == 450);
  VERIF(fabsf(m.frequence - 50.01f) < 0.001f);
  VERIF(fabsf(m.energie2c - 432.1f) < 0.001f);

  /* Trames refusées */
  VERIF(jsy_decode(t, 40, &m) == JSY_ERR_LONGUEUR);
  t[20] ^= 0x10;
  VERIF(jsy_decode(t, sizeof t, &m) == JSY_ERR_CRC);
  t[20] ^= 0x10;
  t[1] = 0x83;
  VERIF(jsy_decode(t, sizeof t, &m) == JSY_ERR_ENTETE);

  /* Table des pas : mêmes bornes que la v9.15 */
  struct { int p; float pas; } cas[] = {
    {-5000, 5}, {-1000, 5}, {-999, 3}, {-800, 3}, {-799, 2}, {-400, 2}, {-301, 1}, {-300, 1},
    {-250, 0.75f}, {-200, 0.75f}, {-150, 0.5f}, {-100, 0.5f}, {-60, 0.1f}, {-50, 0.1f},
    {-40, 0.05f}, {-30, 0.05f}, {-29, 0}, {-1, 0}, {0, 0},
    {1, -0.1f}, {29, -0.1f}, {30, -0.5f}, {50, -0.5f}, {99, -0.5f}, {100, -1}, {200, -2},
    {300, -3}, {400, -4}, {799, -4}, {800, -6}, {999, -6}, {1000, -10}, {5000, -10},
  };
  for (size_t i = 0; i < sizeof cas / sizeof cas[0]; i++) {
    float r = pas_dimmer(cas[i].p);
    if (fabsf(r - cas[i].pas) > 1e-6f) { printf("ÉCHEC pas_dimmer(%d) = %g, attendu %g\n", cas[i].p, r, cas[i].pas); echecs++; }
  }

  printf(echecs ? "%d échec(s)\n" : "OK\n", echecs);
  return echecs != 0;
}
