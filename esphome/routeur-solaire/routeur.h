// Routeur solaire (ESPHome, D1 mini) : décodage du JSY-MK-194 et table de régulation.
// Fonctions pures, sans dépendance ESPHome : testées sur PC par ../../test/test_routeur.c.
#pragma once

#include <stdint.h>
#include <stddef.h>

// ---------------------------------------------------------------------------------------------
// JSY-MK-194 : lecture Modbus RTU de 14 registres de 32 bits à partir de 0x0048
// ---------------------------------------------------------------------------------------------

#define JSY_TRAME_LEN 61          // 3 octets d'en-tête + 56 octets de données + 2 octets de CRC
#define JSY_ADRESSE   0x01
#define JSY_FONCTION  0x03
#define JSY_NB_OCTETS 56

// Esclave 1, fonction 3, registre 0x0048, 14 registres, CRC 0x1844 (octet faible en premier).
static const uint8_t JSY_REQUETE[8] = {0x01, 0x03, 0x00, 0x48, 0x00, 0x0E, 0x44, 0x18};

// Réglage du port du JSY (même trame que vitesse_port_jsy.ino) : diffusion (adresse 0), fonction 16, registre 0x0004
// = 0x0108 → adresse 1, vitesse code 8 = 38 400 bauds. À envoyer à la vitesse actuelle du module (4 800 si neuf).
static const uint8_t JSY_TRAME_38400[11] = {0x00, 0x10, 0x00, 0x04, 0x00, 0x01, 0x02, 0x01, 0x08, 0xAA, 0x12};

typedef struct {
  float tension;      // V
  float intensite1;   // A, canal 1 (ballon)
  int   puissance1;   // W, canal 1 : puissance envoyée au ballon
  float energie1;     // kWh, canal 1 : énergie routée
  uint8_t sens1;
  uint8_t sens2;      // 1 = injection, 0 = soutirage
  float frequence;    // Hz
  float intensite2;   // A, canal 2 (arrivée maison)
  int   puissance2;   // W, canal 2, toujours positive (le sens est dans sens2)
  float energie2;     // kWh, canal 2
  float energie2c;    // kWh, canal 2, consommation
} JsyMesure;

enum { JSY_OK = 0, JSY_ERR_LONGUEUR = -1, JSY_ERR_ENTETE = -2, JSY_ERR_CRC = -3 };

static inline uint16_t modbus_crc16(const uint8_t *p, size_t n) {
  uint16_t crc = 0xFFFF;
  for (size_t i = 0; i < n; i++) {
    crc ^= p[i];
    for (int b = 0; b < 8; b++) crc = (crc & 1) ? (uint16_t)((crc >> 1) ^ 0xA001) : (uint16_t)(crc >> 1);
  }
  return crc;
}

static inline uint32_t be32(const uint8_t *p) {
  return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) | ((uint32_t)p[2] << 8) | (uint32_t)p[3];
}

// Mêmes positions et mêmes facteurs d'échelle que la v9.15 (index dans la trame complète).
static inline int jsy_decode(const uint8_t *t, size_t n, JsyMesure *m) {
  if (n < JSY_TRAME_LEN) return JSY_ERR_LONGUEUR;
  if (t[0] != JSY_ADRESSE || t[1] != JSY_FONCTION || t[2] != JSY_NB_OCTETS) return JSY_ERR_ENTETE;
  uint16_t crc = modbus_crc16(t, JSY_TRAME_LEN - 2);
  if (t[JSY_TRAME_LEN - 2] != (crc & 0xFF) || t[JSY_TRAME_LEN - 1] != (crc >> 8)) return JSY_ERR_CRC;

  m->tension    = be32(t + 3)  * 0.0001f;
  m->intensite1 = be32(t + 7)  * 0.0001f;
  m->puissance1 = (int)(be32(t + 11) * 0.0001);
  m->energie1   = be32(t + 15) * 0.0001f;
  m->sens1      = t[27];
  m->sens2      = t[28];
  m->frequence  = be32(t + 31) * 0.01f;
  m->intensite2 = be32(t + 39) * 0.0001f;
  m->puissance2 = (int)(be32(t + 43) * 0.0001);
  m->energie2   = be32(t + 47) * 0.0001f;
  m->energie2c  = be32(t + 55) * 0.0001f;
  return JSY_OK;
}

// ---------------------------------------------------------------------------------------------
// Régulation : pas d'ajustement du dimmer (en %) selon la puissance réseau, table de la v9.15.
// puissance_reseau > 0 : on soutire ; < 0 : on injecte. Cible : entre -30 W et 0 W d'injection.
// ---------------------------------------------------------------------------------------------

static inline float pas_dimmer(int puissance_reseau) {
  static const struct { int seuil; float pas; } INJECTION[] = {
    {-1000, 5.0f}, {-800, 3.0f}, {-400, 2.0f}, {-300, 1.0f},
    {-200, 0.75f}, {-100, 0.5f}, {-50, 0.1f}, {-30, 0.05f},
  };
  static const struct { int seuil; float pas; } SOUTIRAGE[] = {
    {1000, -10.0f}, {800, -6.0f}, {400, -4.0f}, {300, -3.0f},
    {200, -2.0f}, {100, -1.0f}, {30, -0.5f}, {1, -0.1f},
  };
  for (size_t i = 0; i < sizeof(INJECTION) / sizeof(INJECTION[0]); i++)
    if (puissance_reseau <= INJECTION[i].seuil) return INJECTION[i].pas;
  for (size_t i = 0; i < sizeof(SOUTIRAGE) / sizeof(SOUTIRAGE[0]); i++)
    if (puissance_reseau >= SOUTIRAGE[i].seuil) return SOUTIRAGE[i].pas;
  return 0.0f;  // entre -29 W et 0 W : zone visée, on ne bouge pas
}
