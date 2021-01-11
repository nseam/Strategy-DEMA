/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_DEMA_Params_M1 : DEMAParams {
  Indi_DEMA_Params_M1() : DEMAParams(indi_dema_defaults, PERIOD_M1) {
    period = 12;
    ma_shift = 0;
    applied_price = (ENUM_APPLIED_PRICE)0;
    shift = 0;
  }
} indi_dema_m1;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_DEMA_Params_M1 : StgParams {
  // Struct constructor.
  Stg_DEMA_Params_M1() : StgParams(stg_dema_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)10;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)10;
    price_stop_method = 0;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_dema_m1;
