//+------------------------------------------------------------------+
//|                                                        Order.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <../../../Include/Object.mqh>

class Trade {
 public:
 	enum State { ABORTED = -1, PENDING = 0, ORDER = 1, POSITION = 2 };
 private:
 	State m_State;
 	ulong m_Ticket;
 public:
 	Trade(){}
 
 	Trade(const ulong p_Ticket)
 	   : m_State(PENDING) {
 		SetTrade(p_Ticket);
 	}
 	
 	void SetTrade(const ulong p_Ticket) {
 		m_Ticket = p_Ticket;
 	}
 	
 	void SetTrade(const State p_State) {
 		m_State = p_State;
 	}
 	
 	ulong GetTicket() const { return(m_Ticket); }
 	State GetState() const { return(m_State); }
 	
 	void SetState(const State p_State) { m_State = p_State; }
};

class ReggieTrade : public CObject {
 public:
 	enum TradeType { BUY, SELL };
 	
 	Trade m_ReggieR1Trade;
 	Trade m_ReggieR2Trade;
 private:
 	TradeType m_TradeType;
 public:
 	ReggieTrade(){};
 	
 	ReggieTrade(const TradeType p_TradeType, const ulong p_R1Ticket, const ulong p_R2Ticket)
 		: m_TradeType(p_TradeType) {
 		SetReggieTrade(p_TradeType, p_R1Ticket, p_R2Ticket);
 	}
 	
 	void SetReggieTrade(const TradeType p_TradeType, const ulong p_R1Ticket, const ulong p_R2Ticket) {
 		m_TradeType = p_TradeType;
 		
 		m_ReggieR1Trade.SetTrade(p_R1Ticket);
 		m_ReggieR2Trade.SetTrade(p_R2Ticket);
 	}
 	
 	Trade *GetReggieR1Trade() { return(&m_ReggieR1Trade); }
 	Trade *GetReggieR2Trade() { return(&m_ReggieR2Trade); }
 	
 	TradeType GetTradeType() const { return(m_TradeType); }
 	
 	void SetR1TradeState(const Trade::State p_TradeState) { m_ReggieR1Trade.SetTrade(p_TradeState); }
 	void SetR2TradeState(const Trade::State p_TradeState) { m_ReggieR2Trade.SetTrade(p_TradeState); }
 	
 	void SetOrderType(const TradeType p_TradeType) { m_TradeType = p_TradeType; }
};