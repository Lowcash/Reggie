//+------------------------------------------------------------------+
//|                                                        Order.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

class Order {
 public:
 	enum State { ABORTED = -1, PENDING = 0, PLACED = 1 };

 	int m_Ticket;
 	double m_Price;
 private:
 	State m_State;
 public:
 	Order(){}
 
 	Order(const int p_Ticket, const double p_Price) {
 		SetOrder(p_Ticket, p_Price);
 	}
 		
 	void SetOrder(const int p_Ticket, const double p_Price) {
 		m_Ticket = p_Ticket;
 		m_Price = p_Price;
 		
 		m_State = PENDING;
 	}
 	
 	State GetState() const { return(m_State); }
 	
 	void SetState(const State p_State) { m_State = p_State; }
};

class ReggieOrder {
 public:
 	enum Type { ORDER_BUY, ORDER_SELL };
 	
 	Order m_ReggieR1Order;
 	Order m_ReggieR2Order;
 private:
 	Type m_Type;
 public:
 	ReggieOrder(){};
 	
 	ReggieOrder(const Type p_Type, const int p_R1Ticket, const int p_R2Ticket, const double p_R1Price, const double p_R2Price, const double p_Volume)
 		: m_Type(p_Type) {
 		SetReggieOrder(p_Type, p_R1Ticket, p_R2Ticket, p_R1Price, p_R2Price, p_Volume);
 	}
 	
 	void SetReggieOrder(const Type p_Type, const int p_R1Ticket, const int p_R2Ticket, const double p_R1Price, const double p_R2Price, const double p_Volume) {
 		m_Type = p_Type;
 		
 		m_ReggieR1Order.SetOrder(p_R1Ticket, p_R1Price);
 		m_ReggieR2Order.SetOrder(p_R2Ticket, p_R2Price);
 	}
 	
 	Order *GetReggieR1Order() { return(&m_ReggieR1Order); }
 	Order *GetReggieR2Order() { return(&m_ReggieR2Order); }
 	
 	Type GetType() const { return(m_Type); }
 	
 	void SetType(const Type p_Type) { m_Type = p_Type; }
};