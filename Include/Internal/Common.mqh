//+------------------------------------------------------------------+
//|                                                       Common.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"

double GetForexPipValue() {
   return(_Digits % 2 == 1 ? (_Point * 10) : _Point);
}

int GetNumPipsBetweenPrices(const double p_FirstPrice, const double p_SecondPrice, const double p_PipValue) {
   return(
      MathAbs(
         (int)(p_FirstPrice / p_PipValue) - (int)(p_SecondPrice / p_PipValue)
      )
   );
}