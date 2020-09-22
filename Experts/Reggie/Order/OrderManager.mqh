//+------------------------------------------------------------------+
//|                                                 OrderManager.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../../Include/Internal/Common.mqh"

class ReggieOrderManager {
 private:
 	double m_PipValue, m_LotSize;
 public:
 	ReggieOrderManager(const double p_LotSize)
 		: m_LotSize(p_LotSize) {
 		m_PipValue = GetForexPipValue();
 	}
 
 	ReggieOrder m_ReggieOrders[];
 	
	int m_OrderTicketPointer;
	
	void AnalyzeOrders(const double p_CriticalValue);
	
	int GetActiveTickets() const { return(OrdersTotal()); }
	
 	bool AddOrder(const ReggieOrderType p_OrderType) {
 		bool _IsOrderSuccessful = false;
 		
 		switch(p_OrderType) {
 			case ORDER_UP: {
 				const double _EnterPrice = iHigh(_Symbol, PERIOD_M5, iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 5)) + 3 * m_PipValue /*+ (m_PipValue*MarketInfo(_Symbol, MODE_SPREAD))*/;
 				const double _StopLossPrice = Bid - 3 * m_PipValue;
 				
 				const double _Move = MathAbs(_StopLossPrice - _EnterPrice);
 				
 				const int _R1OrderTicket = OrderSend(_Symbol, OP_BUYSTOP, m_LotSize, _EnterPrice, 3, _StopLossPrice, _EnterPrice + 1 * _Move);
 				const int _R2OrderTicket = OrderSend(_Symbol, OP_BUYSTOP, m_LotSize, _EnterPrice, 3, _StopLossPrice, _EnterPrice + 2 * _Move);
 				
 				if(_R1OrderTicket == -1 || _R2OrderTicket == -1) { 
 					Print("Order failed with error #", GetLastError());
 					
 					return(_IsOrderSuccessful); 
 				}
 				
 				ArrayResize(m_ReggieOrders, ArraySize(m_ReggieOrders) + 1);
 				
 				m_ReggieOrders[ArraySize(m_ReggieOrders) - 1].SetReggieOrder(ORDER_UP, _R1OrderTicket, _R2OrderTicket, _EnterPrice, _EnterPrice, m_LotSize);

 				break;
 			}
 			case ORDER_DOWN: {
 				const double _EnterPrice = iLow(_Symbol, PERIOD_M5, iLowest(_Symbol, PERIOD_M5, MODE_LOW, 5)) - 3 * m_PipValue;
 				const double _StopLossPrice = Bid + 3 * m_PipValue;
 				
 				const double _Move = MathAbs(_StopLossPrice - _EnterPrice);
 				
 				const int _R1OrderTicket = OrderSend(_Symbol, OP_SELLSTOP, m_LotSize, _EnterPrice, 3, _StopLossPrice, _EnterPrice - 1 * _Move);
 				const int _R2OrderTicket = OrderSend(_Symbol, OP_SELLSTOP, m_LotSize, _EnterPrice, 3, _StopLossPrice, _EnterPrice - 2 * _Move);
 				
 				if(_R1OrderTicket == -1 || _R2OrderTicket == -1) { 
 					Print("Order failed with error #", GetLastError());
 					
 					return(_IsOrderSuccessful); 
 				}
 				
 				ArrayResize(m_ReggieOrders, ArraySize(m_ReggieOrders) + 1);
 				
 				m_ReggieOrders[ArraySize(m_ReggieOrders) - 1].SetReggieOrder(ORDER_DOWN, _R1OrderTicket, _R2OrderTicket, _EnterPrice, _EnterPrice, m_LotSize);
 				
 				break;
 			}
 		}
 		
 		_IsOrderSuccessful = true;
 		
 		m_OrderTicketPointer = m_OrderTicketPointer > ArraySize(m_ReggieOrders) ? 0 : m_OrderTicketPointer + 1;
 		
 		return _IsOrderSuccessful;
 	}
};