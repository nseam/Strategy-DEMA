/**
 * @file
 * Implements DEMA strategy based the Double Exponential Moving Average indicator.
 */

// User params.
INPUT float DEMA_LotSize = 0;               // Lot size
INPUT int DEMA_SignalOpenMethod = 0;        // Signal open method (-3-3)
INPUT float DEMA_SignalOpenLevel = 0;       // Signal open level
INPUT int DEMA_SignalOpenFilterMethod = 1;  // Signal open filter method
INPUT int DEMA_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int DEMA_SignalCloseMethod = 0;       // Signal close method (-3-3)
INPUT float DEMA_SignalCloseLevel = 0;      // Signal close level
INPUT int DEMA_PriceStopMethod = 0;         // Price stop method
INPUT float DEMA_PriceStopLevel = 0;        // Price stop level
INPUT int DEMA_TickFilterMethod = 1;        // Tick filter method
INPUT float DEMA_MaxSpread = 4.0;           // Max spread to trade (pips)
INPUT int DEMA_Shift = 0;                   // Shift
INPUT int DEMA_OrderCloseTime = -20;        // Order close time in mins (>0) or bars (<0)
INPUT string __DEMA_Indi_DEMA_Parameters__ =
    "-- DEMA strategy: DEMA indicator params --";                               // >>> DEMA strategy: DEMA indicator <<<
INPUT int DEMA_Indi_DEMA_Period = 12;                                           // Period
INPUT int DEMA_Indi_DEMA_MA_Shift = 0;                                          // MA Shift
INPUT ENUM_APPLIED_PRICE DEMA_Indi_DEMA_Applied_Price = (ENUM_APPLIED_PRICE)0;  // Applied Price
INPUT int DEMA_Indi_DEMA_Shift = 0;                                             // DEMA Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_DEMA_Params_Defaults : DEMAParams {
  Indi_DEMA_Params_Defaults()
      : DEMAParams(::DEMA_Indi_DEMA_Period, ::DEMA_Indi_DEMA_MA_Shift, ::DEMA_Indi_DEMA_Applied_Price,
                   ::DEMA_Indi_DEMA_Shift) {}
} indi_dema_defaults;

// Defines struct with default user strategy values.
struct Stg_DEMA_Params_Defaults : StgParams {
  Stg_DEMA_Params_Defaults()
      : StgParams(::DEMA_SignalOpenMethod, ::DEMA_SignalOpenFilterMethod, ::DEMA_SignalOpenLevel,
                  ::DEMA_SignalOpenBoostMethod, ::DEMA_SignalCloseMethod, ::DEMA_SignalCloseLevel,
                  ::DEMA_PriceStopMethod, ::DEMA_PriceStopLevel, ::DEMA_TickFilterMethod, ::DEMA_MaxSpread,
                  ::DEMA_Shift, ::DEMA_OrderCloseTime) {}
} stg_dema_defaults;

// Struct to define strategy parameters to override.
struct Stg_DEMA_Params : StgParams {
  DEMAParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_DEMA_Params(DEMAParams &_iparams, StgParams &_sparams)
      : iparams(indi_dema_defaults, _iparams.tf), sparams(stg_dema_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_DEMA : public Strategy {
 public:
  Stg_DEMA(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_DEMA *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    DEMAParams _indi_params(indi_dema_defaults, _tf);
    StgParams _stg_params(stg_dema_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<DEMAParams>(_indi_params, _tf, indi_dema_m1, indi_dema_m5, indi_dema_m15, indi_dema_m30,
                                indi_dema_h1, indi_dema_h4, indi_dema_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_dema_m1, stg_dema_m5, stg_dema_m15, stg_dema_m30, stg_dema_h1,
                               stg_dema_h4, stg_dema_h8);
    }
    // Initialize indicator.
    DEMAParams ma_params(_indi_params);
    _stg_params.SetIndicator(new Indi_DEMA(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_DEMA(_stg_params, "DEMA");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_DEMA *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result &= _indi.IsIncreasing(2);
          _result &= _indi.IsIncByPct(_level, 0, 0, 2);
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsIncreasing(3);  // ... 3 consecutive columns are green.
            if (METHOD(_method, 1)) _result &= _indi.IsIncreasing(2, 0, 3);
          }
          break;
        case ORDER_TYPE_SELL:
          _result &= _indi.IsDecreasing(2);
          _result &= _indi.IsDecByPct(_level, 0, 0, 2);
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsDecreasing(3);  // ... 3 consecutive columns are red.
            if (METHOD(_method, 1)) _result &= _indi.IsIncreasing(2, 0, 3);
          }
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_DEMA *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 1:
        _result = _indi[PPREV][0] + _trail * _direction;
        break;
      case 2: {
        int _bar_count = (int)_level * (int)_indi.GetPeriod();
        _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count));
        break;
      }
    }
    return (float)_result;
  }
};
