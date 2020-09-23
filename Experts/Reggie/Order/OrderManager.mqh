//+------------------------------------------------------------------+
//|                                                 OrderManager.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../../Include/Internal/MQL4Helper.mqh"
#include "../../../Include/Internal/Common.mqh"
#include "Order.mqh"

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
	
 	bool AddOrder(const ReggieOrder::Type p_OrderType) {
 		bool _IsOrderSuccessful = false;
 		
 		switch(p_OrderType) {
 			case ReggieOrder::Type::ORDER_BUY: {
 				const double _EnterPrice = iHigh(_Symbol, PERIOD_M5, iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 5)) + 3 * m_PipValue /*+ (m_PipValue*MarketInfo(_Symbol, MODE_SPREAD))*/;
 				const double _StopLossPrice = Bid - 3 * m_PipValue;
 				
 				const double _Move = MathAbs(_StopLossPrice - _EnterPrice);
 				
 			   /*const int _R1OrderTicket = OrderSend(_Symbol, OP_BUYSTOP, m_LotSize, _EnterPrice, 3, _StopLossPrice, _EnterPrice + 1 * _Move);
 				const int _R2OrderTicket = OrderSend(_Symbol, OP_BUYSTOP, m_LotSize, _EnterPrice, 3, _StopLossPrice, _EnterPrice + 2 * _Move);
 				
 				if(_R1OrderTicket == -1 || _R2OrderTicket == -1) { 
 					Print("Order failed with error #", GetLastError());
 					
 					return(_IsOrderSuccessful); 
 				}
 				
 				ArrayResize(m_ReggieOrders, ArraySize(m_ReggieOrders) + 1);
 				
 				m_ReggieOrders[ArraySize(m_ReggieOrders) - 1].SetReggieOrder(ORDER_UP, _R1OrderTicket, _R2OrderTicket, _EnterPrice, _EnterPrice, m_LotSize);

 				break;*/
 			}
 			case ReggieOrder::Type::ORDER_SELL: {
 				const double _EnterPrice = iLow(_Symbol, PERIOD_M5, iLowest(_Symbol, PERIOD_M5, MODE_LOW, 5)) - 3 * m_PipValue;
 				const double _StopLossPrice = Bid + 3 * m_PipValue;
 				
 				const double _Move = MathAbs(_StopLossPrice - _EnterPrice);
 				
 				/*const int _R1OrderTicket = OrderSend(_Symbol, OP_SELLSTOP, m_LotSize, _EnterPrice, 3, _StopLossPrice, _EnterPrice - 1 * _Move);
 				const int _R2OrderTicket = OrderSend(_Symbol, OP_SELLSTOP, m_LotSize, _EnterPrice, 3, _StopLossPrice, _EnterPrice - 2 * _Move);
 				
 				if(_R1OrderTicket == -1 || _R2OrderTicket == -1) { 
 					Print("Order failed with error #", GetLastError());
 					
 					return(_IsOrderSuccessful); 
 				}
 				
 				ArrayResize(m_ReggieOrders, ArraySize(m_ReggieOrders) + 1);
 				
 				m_ReggieOrders[ArraySize(m_ReggieOrders) - 1].SetReggieOrder(ORDER_DOWN, _R1OrderTicket, _R2OrderTicket, _EnterPrice, _EnterPrice, m_LotSize);
 				
 				break;*/
 			}
 		}
 		
 		_IsOrderSuccessful = true;
 		
 		m_OrderTicketPointer = m_OrderTicketPointer > ArraySize(m_ReggieOrders) ? 0 : m_OrderTicketPointer + 1;
 		
 		return _IsOrderSuccessful;
 	}
};

void ReggieOrderManager::AnalyzeOrders(const double p_CriticalValue) {
	Comment("NO_TRADES");
	
	if(ArraySize(m_ReggieOrders) > 0) {
		Order* _R1Order = m_ReggieOrders[0].GetReggieR1Order();
		Order* _R2Order = m_ReggieOrders[0].GetReggieR2Order();
		
		Comment(StringFormat("R1: %s; R2: %s", EnumToString(_R1Order.GetState()), EnumToString(_R2Order.GetState())));
	}
	
	for(int i = 0; i < ArraySize(m_ReggieOrders); ++i) {
		Order* _R1Order = m_ReggieOrders[i].GetReggieR1Order();
		Order* _R2Order = m_ReggieOrders[i].GetReggieR2Order();
		
		Order::State _R1OrderState = _R1Order.GetState();
		Order::State _R2OrderState = _R2Order.GetState();
		
		const ReggieOrder::Type _ReggieOrderType = m_ReggieOrders[i].GetType();

		if(_R1OrderState == Order::State::PLACED) {
			/*if(OrderSelect(_R1Order.m_Ticket, SELECT_BY_TICKET, MODE_HISTORY) && OrderCloseTime() != NULL) {
				_R1Order.SetOrderState(ABORTED);
				
				Print("Modified");
				
				if(!OrderSelect(_R2Order.m_Ticket, SELECT_BY_TICKET)) {
					Print("OrderSelect failed with error #", GetLastError());
				}
				
				if(!OrderModify(OrderTicket(), OrderOpenPrice(), _R2Order.m_Price, OrderTakeProfit(), OrderExpiration())) {
					Print("OrderModify failed with error #", GetLastError());
				}
			}*/
		}
		
		if(_R2OrderState == Order::State::PLACED) {
			/*if(OrderSelect(_R2Order.m_Ticket, SELECT_BY_TICKET, MODE_HISTORY) && OrderCloseTime() != NULL) {
				_R2Order.SetOrderState(Order::State::ABORTED);
			}*/
		}
			
		if(_R1OrderState == Order::State::PENDING &&
			((_ReggieOrderType == ReggieOrder::Type::ORDER_BUY && Ask > _R1Order.m_Price) ||
			(_ReggieOrderType == ReggieOrder::Type::ORDER_SELL && Bid < _R1Order.m_Price)))  {
			_R1Order.SetState(Order::State::PLACED);
		}

		if(_R2OrderState == Order::State::PENDING &&
			((_ReggieOrderType == ReggieOrder::Type::ORDER_BUY && Ask > _R2Order.m_Price) ||
			(_ReggieOrderType == ReggieOrder::Type::ORDER_SELL && Bid < _R2Order.m_Price))) {
			_R2Order.SetState(Order::State::PLACED);
		}	
	}
	
	ReggieOrder _ReggieOrders[];
	
	for(int i = 0; i < ArraySize(m_ReggieOrders); ++i) {
		Order* _R1Order = m_ReggieOrders[i].GetReggieR1Order();
		Order* _R2Order = m_ReggieOrders[i].GetReggieR2Order();
		
		const Order::State _R1OrderState = _R1Order.GetState();
		const Order::State _R2OrderState = _R2Order.GetState();
		
		const ReggieOrder::Type _ReggieOrderType = m_ReggieOrders[i].GetType();
		
		if((_ReggieOrderType == ReggieOrder::Type::ORDER_BUY && p_CriticalValue > Close[1]) ||
			(_ReggieOrderType == ReggieOrder::Type::ORDER_SELL && p_CriticalValue < Close[1])) {
			if(_R1OrderState == Order::State::PENDING) {
				/*if(!OrderDelete(_R1Order.m_Ticket)) {
					Print("Order failed with error #", GetLastError());
				} else {
					_R1Order.SetOrderState(Order::State::ABORTED);
				}*/
					
			}
			if(_R2OrderState == Order::State::PENDING) {
				/*if(!OrderDelete(_R2Order.m_Ticket)) {
					Print("Order failed with error #", GetLastError());
				} else {
					_R2Order.SetOrderState(Order::State::ABORTED);
				}*/
			}
		}
		
		if(!(_R1OrderState == Order::State::ABORTED && _R2OrderState == Order::State::ABORTED)) {
			ArrayResize(_ReggieOrders, ArraySize(_ReggieOrders) + 1);
		
			_ReggieOrders[ArraySize(_ReggieOrders) - 1].SetType( m_ReggieOrders[i].GetType());
			_ReggieOrders[ArraySize(_ReggieOrders) - 1].m_ReggieR1Order = m_ReggieOrders[i].m_ReggieR1Order;
			_ReggieOrders[ArraySize(_ReggieOrders) - 1].m_ReggieR2Order = m_ReggieOrders[i].m_ReggieR2Order;
		}
	}
	
	ArrayFree(m_ReggieOrders); ArrayResize(m_ReggieOrders, ArraySize(_ReggieOrders));

	for(int i = 0; i < ArraySize(_ReggieOrders); ++i) {
		m_ReggieOrders[i].SetType(_ReggieOrders[i].GetType());
		m_ReggieOrders[i].m_ReggieR1Order = _ReggieOrders[i].m_ReggieR1Order;
		m_ReggieOrders[i].m_ReggieR2Order = _ReggieOrders[i].m_ReggieR2Order;
	}
	
	if(ArraySize(m_ReggieOrders) > 0) {
		Order* _R1Order = m_ReggieOrders[0].GetReggieR1Order();
		Order* _R2Order = m_ReggieOrders[0].GetReggieR2Order();
		
		const Order::State _R1OrderState = _R1Order.GetState();
		const Order::State _R2OrderState = _R2Order.GetState();
	}
	
	m_OrderTicketPointer = ArraySize(m_ReggieOrders);
}