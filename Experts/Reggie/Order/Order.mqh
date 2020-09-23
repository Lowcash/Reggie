//+------------------------------------------------------------------+
//|                                                        Order.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <../../../Include/Object.mqh>

class Order {
 public:
 	enum State { ABORTED = -1, PENDING = 0, PLACED = 1 };

 	ulong m_Ticket;
 	double m_Price;
 private:
 	State m_State;
 public:
 	Order(){}
 
 	Order(const ulong p_Ticket, const double p_Price) {
 		SetOrder(p_Ticket, p_Price);
 	}
 		
 	void SetOrder(const ulong p_Ticket, const double p_Price) {
 		m_Ticket = p_Ticket;
 		m_Price = p_Price;
 		
 		m_State = PENDING;
 	}
 	
 	State GetState() const { return(m_State); }
 	
 	void SetState(const State p_State) { m_State = p_State; }
};

class ReggieOrder : public CObject {
 public:
 	enum OrderType { BUY, SELL };
 	
 	Order m_ReggieR1Order;
 	Order m_ReggieR2Order;
 private:
 	OrderType m_OrderType;
 public:
 	ReggieOrder(){};
 	
 	ReggieOrder(const OrderType p_OrderType, const ulong p_R1Ticket, const ulong p_R2Ticket, const double p_R1Price, const double p_R2Price, const double p_Volume)
 		: m_OrderType(p_OrderType) {
 		SetReggieOrder(p_OrderType, p_R1Ticket, p_R2Ticket, p_R1Price, p_R2Price, p_Volume);
 	}
 	
 	void SetReggieOrder(const OrderType p_OrderType, const ulong p_R1Ticket, const ulong p_R2Ticket, const double p_R1Price, const double p_R2Price, const double p_Volume) {
 		m_OrderType = p_OrderType;
 		
 		m_ReggieR1Order.SetOrder(p_R1Ticket, p_R1Price);
 		m_ReggieR2Order.SetOrder(p_R2Ticket, p_R2Price);
 	}
 	
 	Order *GetReggieR1Order() { return(&m_ReggieR1Order); }
 	Order *GetReggieR2Order() { return(&m_ReggieR2Order); }
 	
 	OrderType GetOrderType() const { return(m_OrderType); }
 	
 	void SetOrderType(const OrderType p_OrderType) { m_OrderType = p_OrderType; }
};