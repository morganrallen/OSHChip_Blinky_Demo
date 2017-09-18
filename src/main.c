/**
 * Blinky demo for OSHChip!
 * Much like other blinky demos for nRF5 chips.
 */

#include "nrf_delay.h"
#include "nrf_gpio.h"
#include "boards.h"
#include "nrf.h"

int leds[] = { LED_RED, LED_GREEN, LED_BLUE };

int main(void)
{
  int i = 0;
  for(; i < 3; i++)
    nrf_gpio_cfg_output(leds[i]);

  i = 1;

  while(i++) {
    if(i % 2 == 0)
      nrf_gpio_pin_clear(leds[i % 3]);
    else
      nrf_gpio_pin_set(leds[i % 3]);

    nrf_delay_ms(500);
  }
}
