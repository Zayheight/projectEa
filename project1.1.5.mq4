//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Zmq/Zmq.mqh>
#include <JAson.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+


/*--
    +------------------------------------------------------------------+
                               [ ENUM ]
    +------------------------------------------------------------------+
--*/

enum Bool{
   f=0,//false
   t=1//true
};
enum Mode{
   Bollinger=0,     // BollingerBands
   MA=1,     // MovingAvarage
   WPR=2,      //WiliamsPercentRange
   SX=3 //Sexy
};
enum BBMode{
   ST=0, //Swing Trade
   BO=1, //Break Out
};
enum MAMode{
   CS=0,//Cross Signal
   FS=1,//Follow Signal
};
enum ManageMode{
   Fix=0,//Fixed
   ATR=1,//AverageTrueRange
};
enum CloseMode{
   Fixed=0,//$
   Percent=1,//%
   None=2//False
};
enum MTGMode{
   F=0,//False
   MTGTCCI=1,//MTG TCCI
   MTGStep=2,//MTG Step
};
/*--
    +------------------------------------------------------------------+
                      [ Variable Deceleration & Input ]
    +------------------------------------------------------------------+
--*/
input  double   lots=0.01;
input  MTGMode  SelectMTG=0;//---------------| Select Martingale
input  ManageMode SelectManageOrder=0; //-----SelectManageOrder
sinput string   StepOrdesr="";//Distance(Point)
input  double   pointValue = 50; //Step Order Fix
sinput string   ATRma="";//AverageTrueRange(ATR)
input  int      ATRPeriod=14;//Period
input  float    exponent=2;//Exponent
input ENUM_TIMEFRAMES TimeframeATR=0;//Timeframe
sinput string   TCCImtg ="";//------TCCI MTG
input int       PeriodsTCCIMTG=20;//Periods
input double    DeviationTCCIMTG = 0.0;//Deviation
input ENUM_TIMEFRAMES TimeframeTCCIMTG=0;//Timeframe
input  Bool     Trailingstop=0;//----TrailingStop
input  double   tsStart=500;//Trailing Start(Point)
input  double   tsStop=150;//Trailing Stop(Point)
sinput Mode     SelectMode = Bollinger;
sinput BBMode   BollingerBands=ST; //------BollingerBands
input int       PeriodsBB = 20;//Periods
input double    DeviationBB = 2.0;
input ENUM_TIMEFRAMES TimeframeBB=0;//Timeframe
input MAMode    MovingAverage = CS;//------MovingAverage
input int       MA_Fast = 5;
input int       MA_Slow = 20;
input ENUM_MA_METHOD MA_Method=MODE_SMA;
input ENUM_TIMEFRAMES TimeframeMA=0;//Timeframe
sinput string   WilliamsPercentRange=""; //-----WilliamsPercentRange
input int       PeriodsWPR=20;//Periods
input int       highLevel = -5; //Level High
input int       lowLevel  = -95;//Level Low
input int       candleShift = 1;//Candle Shift
input ENUM_TIMEFRAMES TimeframeWPR=0;//Timeframe
sinput string   Sexy=""; //-----Sexy
extern double distance_input = 400;//Distance
extern int zzpara1 = 12;//Zigzag depth
extern int zzpara2 = 5;//Zigzag deviation
extern int zzpara3 = 3;//Zigzag Backstep
input ENUM_TIMEFRAMES TimeframeZZ=0;//Timeframe
sinput string   SelectTrend = "";
input Bool      MovingAverageIndicator =0;//------MovingAverageIndicator
input int       MAI_Fast = 5; 
input int       MAI_Med = 100;
input int       MAI_Slow = 200;
input ENUM_MA_METHOD MAI_Method=MODE_SMA;
input ENUM_TIMEFRAMES TimeframeMAI=0;//Timeframe
input Bool      TCCI =0;//------TCCI
input int       PeriodsTCCI=20;
input double    DeviationTCCI = 0.0;
input ENUM_TIMEFRAMES TimeframeTCCI=0;//Timeframe
input Bool      STrend=0;//-------SuperTrend
input int       PeriodSTrend=14;//Periods
input double    MultipleSTrend=3.0;//Multiple
input ENUM_TIMEFRAMES TimeframeST=0;//Timeframe
input Bool      ADTrend=0;//------ADX
input int       PeriodADX=14;//Periods
input ENUM_TIMEFRAMES TimeframeADX=0;
input ENUM_APPLIED_PRICE ApplyPriceADX=0;//ApplyPrice
input int       LevelsADX=25;//Levels
input Bool      ARTrend=0;//--------AutomaticRegression
input int       PeriodARTrend=150;//Periods
input ENUM_TIMEFRAMES TimeframeAR=0;//Timeframe
input Bool      HighlowAR=0;//Highlow
input ManageMode   CloseProfit =0;//-------CloseOrder Profit
input double    ProfitTicket = 5.0;//Profit Ticket($)
input double    ProfitType   = 5.0;//Profit Type($)
input double    ProfitSymbol = 5.0;//Profit Symbol($)
input int       PeriodATRCP=14;//Periods
input float     ExponentCP=2;//Exponent
input ManageMode   CloseLoss =0;//-------CloseOrder Loss
input double    LossTicket = 5.0;//Loss Ticket($)
input double    LossType = 5.0;//Loss Type($)
input double    LossSymbol = 5.0;//Loss Symbol($)
input int       PeriodATRCL=14;//Periods
input float     ExponentCL=2;//Exponent
input CloseMode closeEq =0;//-------CloseOrder Equity
input double    closeEqinput = 5.0;//$/%


//CountOrders
int buyCount=0;
int sellCount=0;

double maxmdd=0;

int day;
int permit=0;
//+------------------------------------------------------------------+

double eqProfit=0;
double eqProfitday=0;


double zigZag; 
double zigHigh; 
double zigLow; 
double tempLow,tempHigh;
int tempZigPrev,tempZigCurr;
int high;
int low; 
double highest;
double lowest;
double distance;
double distance1,distance2;
int orderCheck1;

Context context("req");
Socket socket(context,ZMQ_REQ);

Context context2("req2");
Socket socketSend(context2,ZMQ_REQ);

string getJason(){
   CJAVal json;
   json[0]["index"] = 0;
   json[0]["portNumber"]=AccountNumber();
   json[0]["Equity"]=AccountEquity();
   json[0]["Balance"]=AccountBalance();
   json[0]["Profit"]=eqProfitday;
   json[0]["Date"]=TimeToStr(TimeCurrent(),TIME_DATE);
   
   return json.Serialize();
}

void sendData(){
   
}

int OnInit(){
   socket.connect("tcp://127.0.0.1:3030");
   ZmqMsg request(IntegerToString(AccountNumber()));
   socket.send(request);
   ZmqMsg reply;
   socket.recv(reply);
   PrintFormat(reply.getData());
   
   if(reply.getData()=="Allow"){
      permit=1;
      socket.disconnect("tcp://127.0.0.1:3030");
   }else{
      socket.disconnect("tcp://127.0.0.1:3030");
      Alert("Please Register!");
   }
   
   //receiveData();
   eqProfit=AccountEquity()+closeEqinput;
   Print("MODE_LOTSIZE = ", MarketInfo(Symbol(), MODE_LOTSIZE));
   Print("MODE_MINLOT = ", MarketInfo(Symbol(), MODE_MINLOT));
   Print("MODE_LOTSTEP = ", MarketInfo(Symbol(), MODE_LOTSTEP));
   Print("MODE_MAXLOT = ", MarketInfo(Symbol(), MODE_MAXLOT));
   
   
   distance_input = distance_input*Point;
   zigZag = iCustom(Symbol(),TimeframeZZ,"ZigZag",zzpara1,zzpara2,zzpara3,0,0);
   zigHigh = iCustom(Symbol(),TimeframeZZ,"ZigZag",zzpara1,zzpara2,zzpara3,1,0);//Highest from zigzag
   zigLow = iCustom(Symbol(),TimeframeZZ,"ZigZag",zzpara1,zzpara2,zzpara3,2,0);//Lowest from zigzag
   high = iHighest(NULL,0,MODE_HIGH,zzpara1,0);
   low = iLowest(NULL,0,MODE_LOW,zzpara1,0); 
   highest = High[high];
   lowest = Low[low];
   distance = (highest-lowest);
   tempHigh = highest;
   tempLow = lowest;
   
   if(zigZag == zigHigh && zigZag == highest ) {
        tempZigPrev = 1;
   }
   else if(zigZag == zigLow && zigZag == lowest ){
        tempZigPrev = 2;
   }
//---
   
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){
   socket.disconnect("tcp://127.0.0.1:3030");
   socketSend.disconnect("tcp://127.0.0.1:7000");
   context.shutdown();
   context.destroy(0);
   ObjectsDeleteAll();    
}

double checkProfit(int type){
   double sum=0;
   if(type==0||type==1){
      for(int i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderType()==type){
            sum=sum+OrderProfit();
         }
      }
   }else{
      for(int i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         sum=sum+OrderProfit();
      }
   }
   return sum;
}

bool isNewbar(){
   datetime currTime = iTime(Symbol(),Period(),0);
   static datetime prevTime = currTime;

   if(prevTime<currTime){
      prevTime = currTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
double checkMDD(){
   double mddBuy = checkProfit(0);
   
   if(mddBuy<maxmdd){
      maxmdd=mddBuy;
   }
   double mddSell = checkProfit(1);
   if(mddSell<maxmdd){
      maxmdd=mddSell;
   }
   return maxmdd;
}
void openBuy(){
   OrderSend(Symbol(),OP_BUY,lots,Ask ,3,0,0,"Open_buy",0,0,Green);
   buyCount+=1;
}
void openSell(){
   OrderSend(Symbol(),OP_SELL,lots,Bid ,3,0,0,"Open_Sell",0,0,Red);
   sellCount+=1;
}
void closeBuy(){
   OrderClose(OrderTicket(),lots,Bid,3);
   buyCount--;
}
void closeSell(){
   OrderClose(OrderTicket(),lots,Ask,3);
   sellCount--;
}
void closeAllBuy(){
   for(int i=OrdersTotal()-1;i>=0;i--){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==0){
         OrderClose(OrderTicket(),lots,Bid,3);
         buyCount--;
      }
   }
}
void closeAllSell(){
   for(int i=OrdersTotal()-1;i>=0;i--){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==1){
         OrderClose(OrderTicket(),lots,Ask,3);
         sellCount--;
      }
   }
}


/*--
    +------------------------------------------------------------------+
                                    [ Trend ]
    +------------------------------------------------------------------+
--*/

bool ARGTrend(string type){
   if(ARTrend==0) return true;
   bool highlowcheck;
   if(HighlowAR==0) {
      highlowcheck=false;
   }else{
      highlowcheck=true;
   }
   double value1_1=iCustom(Symbol(),TimeframeAR,"automatic-regression-channel-v2",PeriodARTrend,highlowcheck,2,0);
   double value1_2=iCustom(Symbol(),TimeframeAR,"automatic-regression-channel-v2",PeriodARTrend,highlowcheck,2,1);
   
   double value2_1=iCustom(Symbol(),TimeframeAR,"automatic-regression-channel-v2",PeriodARTrend,highlowcheck,0,0);
   double value2_2=iCustom(Symbol(),TimeframeAR,"automatic-regression-channel-v2",PeriodARTrend,highlowcheck,0,1);
   
   double value3_1=iCustom(Symbol(),TimeframeAR,"automatic-regression-channel-v2",PeriodARTrend,highlowcheck,1,0);
   double value3_2=iCustom(Symbol(),TimeframeAR,"automatic-regression-channel-v2",PeriodARTrend,highlowcheck,1,1);
   
   double value4_1=iCustom(Symbol(),TimeframeAR,"automatic-regression-channel-v2",PeriodARTrend,highlowcheck,3,0);
   double value4_2=iCustom(Symbol(),TimeframeAR,"automatic-regression-channel-v2",PeriodARTrend,highlowcheck,3,1);
   
   double checkValue1 = value1_1-value1_2;
   double checkValue2 = value2_1-value2_2;
   double checkValue3 = value3_1-value3_2;
   double checkValue4 = value4_1-value4_2;
   
   if(type=="Buy"){
      double PriceAsk = MarketInfo(Symbol(), MODE_ASK);
      if(PriceAsk>value2_1 || PriceAsk<value3_1) return false;
      if((checkValue1>=0)&&(checkValue2>=0)&&(checkValue3>=0)&&(checkValue4>=0)){
         return true;
      }
   }else{
      double PriceBid = MarketInfo(Symbol(), MODE_BID);
      if(PriceBid>value2_1 || PriceBid<value3_1) return false;
      if((checkValue1<0)&&(checkValue2<0)&&(checkValue3<0)&&(checkValue4<0)){
         return true;
      }
   }
   return false;
}
bool ADXTrend(string type){
   if(ADTrend==0) return true;
   double adx=iADX(Symbol(),TimeframeADX,PeriodADX,ApplyPriceADX,0,0);
   double diplus=iADX(Symbol(),TimeframeADX,PeriodADX,ApplyPriceADX,MODE_PLUSDI,0);
   double diminus=iADX(Symbol(),TimeframeADX,PeriodADX,ApplyPriceADX,MODE_MINUSDI,0);
   if(adx<=LevelsADX)return false;
   
   if(type=="Buy"){
      if(diplus>diminus){
         return true;
      }
   }else{
      if(diminus>diplus){
         return true;
      }
   }
   return false;
}
bool SuperTrend(string type){
   if(STrend==0) return true;
   
   double strend_red   = iCustom(Symbol(),TimeframeST,"Super Trend 01",PeriodSTrend,MultipleSTrend,1,0);
   double strend_green = iCustom(Symbol(),TimeframeST,"Super Trend 01",PeriodSTrend,MultipleSTrend,0,0);
   
   if(strend_red!=EMPTY_VALUE && strend_green!=EMPTY_VALUE)return false;
   
   if(type=="Buy"){
      if(strend_green!=EMPTY_VALUE && strend_red==EMPTY_VALUE){//GreenState
         return true;
      }
   }
   else{
      if(strend_red!=EMPTY_VALUE && strend_green==EMPTY_VALUE){//RedState
         return true;
      }
   }
   return false;
}
bool TCCITrend(string type){
   if(TCCI==0)return true;
   double tcci_green = iCustom(Symbol(),TimeframeTCCI,"TCCI",0,PeriodsTCCI,0,0,1,1,DeviationTCCI,1,0); 
   double tcci_red = iCustom(Symbol(),TimeframeTCCI,"TCCI",0,PeriodsTCCI,0,0,1,1,DeviationTCCI,2,0);
   
   if(tcci_green!=EMPTY_VALUE&&tcci_red!=EMPTY_VALUE)return false;
   if(type=="Buy"){
      if(tcci_green!=EMPTY_VALUE && tcci_red==EMPTY_VALUE){//Green State
         return true;
      }
   }
   else{
      if(tcci_red!=EMPTY_VALUE && tcci_green==EMPTY_VALUE){//Red State
         return true;
      }
   }
   return false;
}

bool MovingAverageTrend(string type){
   if(MovingAverageIndicator==0)return true;
   double fastMAI = iMA(Symbol(),TimeframeMAI,MAI_Fast,0,MAI_Method,PRICE_CLOSE,0);
   double medMAI  = iMA(Symbol(),TimeframeMAI,MAI_Med,0,MAI_Method,PRICE_CLOSE,0);
   double slowMAI = iMA(Symbol(),TimeframeMAI,MAI_Slow,0,MAI_Method,PRICE_CLOSE,0);
   if(type=="Buy"){
      if((fastMAI>medMAI&&fastMAI>slowMAI)&&medMAI>slowMAI){
         return true;
      }
   }
   else{
      if((slowMAI>medMAI && slowMAI>fastMAI)&& medMAI>fastMAI){ //5<10<20
         return true;
      }
   }
   return false;
}

bool checkTrend(string type){
   return (MovingAverageTrend(type)&&TCCITrend(type)&&SuperTrend(type)&&ARGTrend(type)&&ADXTrend(type));
}

/*--
    +------------------------------------------------------------------+
                            [ Open Order ]
    +------------------------------------------------------------------+
--*/
void openOrder(){
   if(SelectMode==0){//Bollinger Bands
      double upper1 = iBands(Symbol(),TimeframeBB,PeriodsBB,DeviationBB,0,PRICE_CLOSE,MODE_UPPER,0);
      double upper2 = iBands(Symbol(),TimeframeBB,PeriodsBB,DeviationBB,0,PRICE_CLOSE,MODE_UPPER,1);
      double lower1 = iBands(Symbol(),TimeframeBB,PeriodsBB,DeviationBB,0,PRICE_CLOSE,MODE_LOWER,0);
      double lower2 = iBands(Symbol(),TimeframeBB,PeriodsBB,DeviationBB,0,PRICE_CLOSE,MODE_LOWER,1);
      double Close1 = iClose(Symbol(),Period(),0);
      double Close2 = iClose(Symbol(),Period(),1);
      if(upper1 > Close1 && upper2 < Close2){
         //-----Upper Bound----//
         if(BollingerBands==0 && checkTrend("Sell")){//SwingTrade
            if(sellCount==0){
               openSell();
            }
         }else if(BollingerBands==1 && checkTrend("Buy")){//BreakOut
            if(buyCount==0){
               openBuy();
            }
         }
      }
      if(lower1 < Close1 && lower2 > Close2){
         //-----Lower Bound----//
         if(BollingerBands==0 && checkTrend("Buy")){//SwingTrade
            if(buyCount==0){
               openBuy();
            }
         }else if(BollingerBands==1 && checkTrend("Sell")){//BreakOut
            if(sellCount==0){
               openSell();
            }
         }
      }
   }else if(SelectMode==1){ //MovingAverage
      double slowMA1 = iMA(NULL,TimeframeMA,MA_Slow,0,MA_Method,PRICE_CLOSE,0);
      double slowMA2 = iMA(NULL,TimeframeMA,MA_Slow,0,MA_Method,PRICE_CLOSE,1);
      double fastMA1 = iMA(NULL,TimeframeMA,MA_Fast,0,MA_Method,PRICE_CLOSE,0);
      double fastMA2 = iMA(NULL,TimeframeMA,MA_Fast,0,MA_Method,PRICE_CLOSE,1);
      if((fastMA2<slowMA2)&&(fastMA1>slowMA1)){
         if(MovingAverage==0 && checkTrend("Buy")){
            if(buyCount==0){
               openBuy();
            }
         }else if(MovingAverage==1 && checkTrend("Sell")){
            if(sellCount==0){
               openSell();
             }
         }
      }
      if((fastMA2>slowMA2)&&(fastMA1<slowMA1)){
         if(MovingAverage==0 && checkTrend("Sell")){
            if(sellCount==0){
               openSell();
            }
         }else if(MovingAverage==1 && checkTrend("Buy")){
            if(buyCount==0){
               openBuy();
            }
         }
      }
   }else if(SelectMode==2){ //Williams%Range
      double wprValue = iWPR(NULL,TimeframeWPR,PeriodsWPR,candleShift);
      if(checkTrend("Sell") && (wprValue>highLevel)){
         if(sellCount==0){
            openSell();
         }
      }
      if(checkTrend("Buy") &&(wprValue<lowLevel)){
         if(buyCount==0){
            openBuy();
         }
      }
   }else if(SelectMode==3){//Sexy
      zigZag = iCustom(Symbol(),TimeframeZZ,"ZigZag",zzpara1,zzpara2,zzpara3,0,0);
      zigHigh = iCustom(Symbol(),TimeframeZZ,"ZigZag",zzpara1,zzpara2,zzpara3,1,0);
      zigLow = iCustom(Symbol(),TimeframeZZ,"ZigZag",zzpara1,zzpara2,zzpara3,2,0);
      
      high = iHighest(NULL,0,MODE_HIGH,zzpara1,0);
      low = iLowest(NULL,0,MODE_LOW,zzpara1,0); 
      
      highest = High[high];
      lowest = Low[low];
     
      if(zigZag == zigHigh && zigZag == highest ) {
           tempZigCurr = 1;
      }
      else if(zigZag == zigLow && zigZag == lowest ){
           tempZigCurr = 2;
      }
      
      // 1-1
      if(zigZag == zigHigh && zigZag == highest && zigZag >= tempHigh && tempZigPrev == tempZigCurr ) {
            distance = (zigZag-tempLow);
            tempHigh = zigHigh;
            tempZigPrev = tempZigCurr;
      } //2-2
      else if(zigZag == zigLow && zigZag == lowest && zigZag <= tempLow && tempZigPrev == tempZigCurr ){
           distance = (tempHigh-zigZag);
           tempLow = zigLow;
           tempZigPrev = tempZigCurr;
      } // 2-1
      else if(zigZag == zigHigh && zigZag == highest && tempZigPrev != tempZigCurr ) 
      {
            distance = (zigZag-tempLow);
            tempHigh = zigHigh;
            tempZigPrev = tempZigCurr;
            orderCheck1 = 1;
            distance1 = 0;
            distance2 =0;
      } // 1-2 
      else if(zigZag == zigLow && zigZag == lowest  && tempZigPrev != tempZigCurr )
      {
           distance = (tempHigh-zigZag);
           tempLow = zigLow;
           tempZigPrev = tempZigCurr;
           orderCheck1 = 1;
           distance1 = 0;
           distance2 =0;
      }
      else {
            distance1 = (tempHigh-tempLow);
            if (tempZigCurr == 1)  // 
            {
               distance2 = (Bid-tempLow);
            }
            else
            {
               distance2 = (tempHigh-Ask);
            }
            
      }
      
     
      if(distance2 > distance_input && orderCheck1 == 1 ){
         if (tempZigCurr==1){
            if(sellCount==0 && checkTrend("Sell")){
               openSell();
            }
         }
         else{
            if(buyCount==0&& checkTrend("Buy")){
               openBuy();
            }
         }
         orderCheck1 = 0;
      }
            
      
      Comment(  "\nDistance1:       ",distance1/Point,
             "\nDistance2:       ",distance2/Point,
             "\nDistance_input:  ",distance_input/Point,
             "\ntempZigCurr:     ",tempZigCurr
             );
   }
}

/*--
    +------------------------------------------------------------------+
                            [ Close Order ]
    +------------------------------------------------------------------+
--*/

void closeOrder(){
   //Close Equity
   if(closeEq==0){
         //10010 - 5 = 10005 =>  10
      if(AccountEquity()>=eqProfit){
         for(int i=OrdersTotal()-1;i>=0;i--){
            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if(OrderType()==0){//OP_BUYฃ
               //Print("test1");
               closeBuy();
            }
            else if(OrderType()==1){//OP_Sell
               //Print("test1");
               closeSell();
            }
         }
         eqProfit=AccountEquity()+closeEqinput;
      }
   }else if(closeEq==1){
      if(AccountEquity()-eqProfit>=((closeEqinput/100)*eqProfit)){
         for(int i=OrdersTotal()-1;i>=0;i--){
            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if(OrderType()==0){//OP_BUY
               closeBuy();
            }
            else if(OrderType()==1){//OP_Sell
               closeSell();
            }
         }
         eqProfit=AccountEquity();
      }
   }


   if(CloseProfit==0){
      /*-------Check Profit OrdetTicket-------*/
      for(int i=OrdersTotal()-1;i>=0;i--){
         if(ProfitTicket==0) break;
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderProfit()>ProfitTicket){
            if(OrderType()==0){//OP_BUY
               //Print("test2");
               closeBuy();
            }
            else if(OrderType()==1){//OP_Sell
               closeSell();
            }
         }
      }
      
      /*-------Check Profit OrdetType-------*/
      if(checkProfit(0)>= ProfitType){
         for(int i=OrdersTotal()-1;i>=0;i--){
            if(ProfitType==0) break;
            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if(OrderType()==0){
                //Print("test3");
                closeBuy();
            }
         }
      }
      if(checkProfit(1)>=ProfitType){
         for(int i=OrdersTotal()-1;i>=0;i--){
            if(ProfitType==0) break;
            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if(OrderType()==1){
                closeSell();
            }
         }
      }
      //-------Check Profit Symbol-------
      if(checkProfit(3)>=ProfitSymbol){
         for(int i=OrdersTotal()-1;i>=0;i--){
            if(ProfitSymbol==0) break;
            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if(OrderType()==0){//OP_BUY
               //Print("test4");
               closeBuy();
            }
            else if(OrderType()==1){//OP_Sell
               closeSell();
            }
         }
      }
      
   }
   else if(CloseProfit==1){
      double atr = (iATR(Symbol(),0,PeriodATRCP,1) * ExponentCP);
      for(int i=OrdersTotal()-1;i>=0;i--){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         double entryprice = OrderOpenPrice();
         if(OrderType()==0){//OP_BUY
         double takeprofit=OrderOpenPrice()+atr;
         if(Ask>=takeprofit){
               closeBuy();
            }
         }
         else if(OrderType()==1){//OP_Sell
             double takeprofit=OrderOpenPrice()-atr;
            if(Bid<=takeprofit){
               closeSell();
            }
         }
         
      }
   }
   
   if(CloseLoss==0){
      /*-------Check Loss OrdetTicket-------*/
      for(int i=OrdersTotal()-1;i>=0;i--){
         if(LossTicket==0) break;
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderProfit()<=(LossTicket*(-1))){
            if(OrderType()==0){//OP_BUY
               closeBuy();
            }
            else if(OrderType()==1){//OP_Sell
               closeSell();
            }
         }
      }
           /*-------Check Loss OrdetType-------*/
      if(checkProfit(0)<= LossType*(-1)){
         if(LossType!=0){
            for(int i=OrdersTotal()-1;i>=0;i--){
               OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
               if(OrderType()==0){
                   closeBuy();
               }
            }
         }
      }
      if(checkProfit(1)<=LossType*(-1)){
         if(LossType!=0){
            for(int i=OrdersTotal()-1;i>=0;i--){
               OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
               if(OrderType()==1){
                   closeSell();
               }
            }
         }
      }
      //-------Check Loss Symbol-------//
      if(checkProfit(3)<=LossSymbol*(-1)){
         if(LossSymbol!=0){
            for(int i=OrdersTotal()-1;i>=0;i--){
               if(ProfitSymbol==0) break;
               OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
               if(OrderType()==0){//OP_BUY
                  closeBuy();
               }
               else if(OrderType()==1){//OP_Sell
                  closeSell();
               }
            }
         }
      }
   }
   else if(CloseLoss==1){
      double atr = (iATR(Symbol(),0,PeriodATRCL,1) * ExponentCL);
      for(int i=OrdersTotal()-1;i>=0;i--){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderType()==0){//OP_BUY
            double stoploss=OrderOpenPrice()-atr;
            if(Ask<=stoploss){
               closeBuy();
            }
         }
         else if(OrderType()==1){//OP_Sell
             double stoploss=OrderOpenPrice()+atr;
            if(Bid>=stoploss){
               closeSell();
            }
         }
      
      }
   }
   
   
   
}
/*--
    +------------------------------------------------------------------+
                            [ Manage Order ]
    +------------------------------------------------------------------+
--*/


bool TCCIMTG(string type){
   double tcci_green = iCustom(Symbol(),TimeframeTCCIMTG,"TCCI",0,PeriodsTCCIMTG,0,0,1,1,DeviationTCCIMTG,1,0); 
   double tcci_red   = iCustom(Symbol(),TimeframeTCCIMTG,"TCCI",0,PeriodsTCCIMTG,0,0,1,1,DeviationTCCIMTG,2,0);
   
   if(tcci_green!=EMPTY_VALUE&&tcci_red!=EMPTY_VALUE)return false;
   if(type=="Buy"){
      if(tcci_green!=EMPTY_VALUE && tcci_red==EMPTY_VALUE){//Green State
         return true;
      }
   }
   else{
      if(tcci_red!=EMPTY_VALUE && tcci_green==EMPTY_VALUE){//Red State
         return true;
      }
   }
   return false;
}

void manageOrder(){
   double point=pointValue*_Point;
   
   int checkBuy = 1;
   int checkSell = 1;
   
   /*Tailing Stop*/
   if(Trailingstop==1){
      for(int i=OrdersTotal()-1;i>=0;i--){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderType()==0){
            if(Bid>=OrderOpenPrice()+(tsStart*_Point)&& OrderStopLoss()<Bid-(tsStop*_Point)){
               double StopLoss = Bid-(tsStop*_Point);
               //Print(StopLoss,OrderOpenPrice());
               OrderModify(OrderTicket(),OrderOpenPrice(),StopLoss,OrderTakeProfit(),0,CLR_NONE);
            }
         }
         else{
            if(OrderStopLoss()==0){
               if(Ask<=OrderOpenPrice()-(tsStart*_Point)){
                  double StopLoss = Ask+(tsStop*_Point);
                  OrderModify(OrderTicket(),OrderOpenPrice(),StopLoss,OrderTakeProfit(),0,CLR_NONE);
               }
            }
            else{
               if(Ask<=OrderOpenPrice()-(tsStart*_Point) && OrderStopLoss()> Ask+(tsStop*_Point)){
                  double StopLoss = Ask+(tsStop*_Point);
                  OrderModify(OrderTicket(),OrderOpenPrice(),StopLoss,OrderTakeProfit(),0,CLR_NONE);
                  
               }
            }
         }
      }
   }
   
   
   
   if(SelectMTG==0) return;
   
   if(SelectManageOrder==0){
      for(int i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderType()==0){// OP_BUY 
            if(checkBuy!=buyCount){
               checkBuy++;
               continue;
            }
            if(MarketInfo(Symbol(), MODE_ASK)<=(OrderOpenPrice()- point)){
               if(SelectMTG==1){
                  if(TCCIMTG("Buy")){
                     openBuy();
                  }
               }
               else{
                  openBuy();
               }
            }
         }
         else if(OrderType()==1){//OP_SELL
            if(checkSell!=sellCount){
               checkSell++;
               continue;
            }
            if(MarketInfo(Symbol(), MODE_BID)>(OrderOpenPrice()+point)){
               if(SelectMTG==1){
                  if(TCCIMTG("Sell")){
                     openSell();
                  }
               }
               else{
                  openSell();
               }
            }
         }
      }
   }else if(SelectManageOrder==1){
      //double atr = (iCustom(Symbol(),0,"ATR",14,0,1) * exponent);
      double atr = (iATR(Symbol(),0,ATRPeriod,0) * exponent);
      
      for(int i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderType()==0){// OP_BUY 
            if(checkBuy!=buyCount){
               checkBuy++;
               continue;
            }
            if(MarketInfo(Symbol(), MODE_ASK)<=(OrderOpenPrice()- atr)){
               if(SelectMTG==1){
                  if(TCCIMTG("Buy")){
                     openBuy();
                  }
               }
               else{
                  openBuy();
               }
            }
         }
         else if(OrderType()==1){//OP_SELL
            if(checkSell!=sellCount){
               checkSell++;
               continue;
            }
            if(MarketInfo(Symbol(), MODE_BID)>(OrderOpenPrice()+ atr)){
               if(SelectMTG==1){
                  if(TCCIMTG("Sell")){
                     openSell();
                  }
               }
               else{
                  openSell();
               }
            }
         }
      }
   }
   
   
   
}


void checkOrder(){
   int count = OrdersTotal();
   int countBuy=0;
   int countSell=0;
   for(int i = count-1;i>=0;i--){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(OrderType()==0){
            countBuy++;
         }
         else if(OrderType()==1){
            countSell++;
         }
      }
   }
   if(buyCount!=countBuy){
      buyCount=buyCount -(buyCount-countBuy);
   
   }
   if(sellCount!=countSell){
      sellCount=sellCount - (sellCount-countSell);
   }

}


//+------------------------------------------------------------------+
int countCandle=0;

void buttonEvent  (){
   if(ObjectGetInteger(ChartID(), "buybutton",OBJPROP_STATE)){
      int PressedButton=MessageBox("Open buy?","Confirm open buy",MB_OKCANCEL);
      if(PressedButton==1){
         openBuy();
      }
      openBuy();
      ObjectSetInteger(ChartID(), "buybutton",OBJPROP_STATE,false);
   }
   
   if(ObjectGetInteger(ChartID(), "sellbutton",OBJPROP_STATE)){
      int PressedButton=MessageBox("Open sell?","Confirm open sell",MB_OKCANCEL);
      if(PressedButton==1){
         openSell();
      }
      ObjectSetInteger(ChartID(), "sellbutton",OBJPROP_STATE,false);
   }
   
   if(ObjectGetInteger(ChartID(), "closebuybutton",OBJPROP_STATE)){
      int PressedButton=MessageBox("Close all buy?","Close all buy",MB_OKCANCEL);
      if(PressedButton==1){
         closeAllBuy();
      }
      ObjectSetInteger(ChartID(), "closebuybutton",OBJPROP_STATE,false);
   }
   
   if(ObjectGetInteger(ChartID(), "closesellbutton",OBJPROP_STATE)){
      int PressedButton=MessageBox("Close all sell?","Close all sell",MB_OKCANCEL);
      if(PressedButton==1){
         closeAllSell();
      }
      ObjectSetInteger(ChartID(), "closesellbutton",OBJPROP_STATE,false);
   }
   if(ObjectGetInteger(ChartID(), "closeallbutton",OBJPROP_STATE)){
      int PressedButton=MessageBox("Close all?","Close all",MB_OKCANCEL);
      if(PressedButton==1){
         for(int i=OrdersTotal()-1;i>=0;i--){
            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if(OrderType()==0){//OP_BUY
               closeBuy();
            }
            else if(OrderType()==1){//OP_Sell
               closeSell();
            }
            
         }
      }
      ObjectSetInteger(ChartID(), "closeallbutton",OBJPROP_STATE,false);
   }
}

void checkEquity(){
   if(OrdersTotal()==0 && eqProfit-AccountEquity()<=closeEqinput){
      eqProfit=AccountEquity()+closeEqinput;
   }
}



void OnTick(){
   if(permit==1){
      
      datetime LocalTime=TimeLocal();
      MqlDateTime DateTimeStructure;
      
      TimeToStruct(LocalTime,DateTimeStructure);
      
      if(DateTimeStructure.day_of_week!=day){
         day=DateTimeStructure.day_of_week;
         Print("New day yey");
         eqProfitday = AccountEquity()-eqProfit;
         eqProfit=eqProfit+eqProfitday;
         
         if(socketSend.connect("tcp://127.0.0.1:7000")){
            Print("bind success");
         }
         Print(getJason());
         ZmqMsg request(getJason());
         socketSend.send(request);
         ZmqMsg reply;
         socketSend.recv(reply);
         Print(reply.getData());
      }
      
      buttonEvent();
      checkEquity();
      manageOrder();
      closeOrder();
      checkOrder();
      createLabel();
      openOrder();
   }
   
}

void createLabel(){
   ObjectCreate("Profit",OBJ_LABEL,0,0,0);
   ObjectSet("Profit",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("Profit",OBJPROP_XDISTANCE,20);
   ObjectSet("Profit",OBJPROP_YDISTANCE,20);
   ObjectSetText("Profit","Profit",10,"Arial",White);
   
   ObjectCreate("BuyProfit",OBJ_LABEL,0,0,0);
   ObjectSet("BuyProfit",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("BuyProfit",OBJPROP_XDISTANCE,20);
   ObjectSet("BuyProfit",OBJPROP_YDISTANCE,40);
   
   ObjectSetText("BuyProfit","Buy:"+DoubleToStr(checkProfit(0),2),10,"Arial",White);
   
   ObjectCreate("SellProfit",OBJ_LABEL,0,0,0);
   ObjectSet("SellProfit",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("SellProfit",OBJPROP_XDISTANCE,20);
   ObjectSet("SellProfit",OBJPROP_YDISTANCE,60);
   
   ObjectSetText("SellProfit","Sell: "+ DoubleToStr(checkProfit(1),2),10,"Arial",White);
   
   ObjectCreate("space",OBJ_LABEL,0,0,0);
   ObjectSet("space",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("space",OBJPROP_XDISTANCE,20);
   ObjectSet("space",OBJPROP_YDISTANCE,80);
   ObjectSetText("space","-----------",10,"Arial",White);
   
   ObjectCreate("Equity",OBJ_LABEL,0,0,0);
   ObjectSet("Equity",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("Equity",OBJPROP_XDISTANCE,20);
   ObjectSet("Equity",OBJPROP_YDISTANCE,100);
   ObjectSetText("Equity","Equity:"+DoubleToStr(AccountEquity(),2),10,"Arial",White);
   
   
   ObjectCreate("Balance",OBJ_LABEL,0,0,0);
   ObjectSet("Balance",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("Balance",OBJPROP_XDISTANCE,20);
   ObjectSet("Balance",OBJPROP_YDISTANCE,120);
   ObjectSetText("Balance","Balance:"+DoubleToStr(AccountBalance(),2),10,"Arial",White);
   
   ObjectCreate("space2",OBJ_LABEL,0,0,0);
   ObjectSet("space2",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("space2",OBJPROP_XDISTANCE,20);
   ObjectSet("space2",OBJPROP_YDISTANCE,140);
   ObjectSetText("space2","-----------",10,"Arial",White);
   
   ObjectCreate("OrdersTotal",OBJ_LABEL,0,0,0);
   ObjectSet("OrdersTotal",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("OrdersTotal",OBJPROP_XDISTANCE,20);
   ObjectSet("OrdersTotal",OBJPROP_YDISTANCE,160);
   ObjectSetText("OrdersTotal","OrdersTotal",10,"Arial",White);
   
   ObjectCreate("OrderSell",OBJ_LABEL,0,0,0);
   ObjectSet("OrderSell",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("OrderSell",OBJPROP_XDISTANCE,20);
   ObjectSet("OrderSell",OBJPROP_YDISTANCE,180);
   ObjectSetText("OrderSell","Sell :"+sellCount,10,"Arial",White);
   
   ObjectCreate("OrderBuy",OBJ_LABEL,0,0,0);
   ObjectSet("OrderBuy",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("OrderBuy",OBJPROP_XDISTANCE,20);
   ObjectSet("OrderBuy",OBJPROP_YDISTANCE,200);
   ObjectSetText("OrderBuy","Buy :"+buyCount,10,"Arial",White);
   
   ObjectCreate("MDD",OBJ_LABEL,0,0,0);
   ObjectSet("MDD",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("MDD",OBJPROP_XDISTANCE,20);
   ObjectSet("MDD",OBJPROP_YDISTANCE,240);
   ObjectSetText("MDD","Max Drawdown :"+DoubleToStr(checkMDD(),2),10,"Arial",White);
   
   ObjectCreate("eq",OBJ_LABEL,0,0,0);
   ObjectSet("eq",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSet("eq",OBJPROP_XDISTANCE,20);
   ObjectSet("eq",OBJPROP_YDISTANCE,260);
   ObjectSetText("eq","Equity Target :"+DoubleToStr(eqProfit,2),10,"Arial",White);
   
   
   ObjectCreate(0,"buybutton",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"buybutton",OBJPROP_XDISTANCE, 190) ;
   ObjectSetInteger(0,"buybutton",OBJPROP_YDISTANCE, 290);
   ObjectSetInteger(0,"buybutton",OBJPROP_XSIZE, 90) ;
   ObjectSetInteger(0,"buybutton",OBJPROP_YSIZE, 40);
   ObjectSetInteger(0,"buybutton",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"buybutton",OBJPROP_FONT,10);
   ObjectSetString(0,"buybutton",OBJPROP_TEXT,"Open Buy");
   ObjectSetInteger(0,"buybutton",OBJPROP_BGCOLOR,Green);
   ObjectSetInteger(0,"buybutton",OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,"buybutton",OBJPROP_COLOR, White);
   
   ObjectCreate(0,"sellbutton",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"sellbutton",OBJPROP_XDISTANCE, 100) ;
   ObjectSetInteger(0,"sellbutton",OBJPROP_YDISTANCE, 290);
   ObjectSetInteger(0,"sellbutton",OBJPROP_XSIZE, 90) ;
   ObjectSetInteger(0,"sellbutton",OBJPROP_YSIZE, 40);
   ObjectSetInteger(0,"sellbutton",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"sellbutton",OBJPROP_FONT,10);
   ObjectSetString(0,"sellbutton",OBJPROP_TEXT,"Open Sell");
   ObjectSetInteger(0,"sellbutton",OBJPROP_BGCOLOR,Red);
   ObjectSetInteger(0,"sellbutton",OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,"sellbutton",OBJPROP_COLOR, White);
   
   ObjectCreate(0,"closebuybutton",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"closebuybutton",OBJPROP_XDISTANCE, 190) ;
   ObjectSetInteger(0,"closebuybutton",OBJPROP_YDISTANCE, 330);
   ObjectSetInteger(0,"closebuybutton",OBJPROP_XSIZE, 90) ;
   ObjectSetInteger(0,"closebuybutton",OBJPROP_YSIZE, 40);
   ObjectSetInteger(0,"closebuybutton",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"closebuybutton",OBJPROP_FONT,10);
   ObjectSetString(0,"closebuybutton",OBJPROP_TEXT,"Close Buy");
   ObjectSetInteger(0,"closebuybutton",OBJPROP_BGCOLOR,Gray);
   ObjectSetInteger(0,"closebuybutton",OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,"closebuybutton",OBJPROP_COLOR, White);
   
   ObjectCreate(0,"closesellbutton",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"closesellbutton",OBJPROP_XDISTANCE, 100) ;
   ObjectSetInteger(0,"closesellbutton",OBJPROP_YDISTANCE, 330);
   ObjectSetInteger(0,"closesellbutton",OBJPROP_XSIZE, 90) ;
   ObjectSetInteger(0,"closesellbutton",OBJPROP_YSIZE, 40);
   ObjectSetInteger(0,"closesellbutton",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"closesellbutton",OBJPROP_FONT,10);
   ObjectSetString(0,"closesellbutton",OBJPROP_TEXT,"Close Sell");
   ObjectSetInteger(0,"closesellbutton",OBJPROP_BGCOLOR,Gray);
   ObjectSetInteger(0,"closesellbutton",OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,"closesellbutton",OBJPROP_COLOR, White);
   
   ObjectCreate(0,"closeallbutton",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"closeallbutton",OBJPROP_XDISTANCE, 190) ;
   ObjectSetInteger(0,"closeallbutton",OBJPROP_YDISTANCE, 370);
   ObjectSetInteger(0,"closeallbutton",OBJPROP_XSIZE, 180) ;
   ObjectSetInteger(0,"closeallbutton",OBJPROP_YSIZE, 40);
   ObjectSetInteger(0,"closeallbutton",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"closeallbutton",OBJPROP_FONT,10);
   ObjectSetString(0,"closeallbutton",OBJPROP_TEXT,"Close All");
   ObjectSetInteger(0,"closeallbutton",OBJPROP_BGCOLOR,Gray);
   ObjectSetInteger(0,"closeallbutton",OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,"closeallbutton",OBJPROP_COLOR, White);
}

