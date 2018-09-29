//+------------------------------------------------------------------+
//|                                   Copyright 2016, Erlon F. Souza |
//|                                       https://github.com/erlonfs |
//+------------------------------------------------------------------+

#property copyright "Copyright 2016, Erlon F. Souza"
#property link      "https://github.com/erlonfs"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <BadRobot.Framework\BadRobotUI.mqh>

class FirstCandle : public BadRobotUI
{
private:
	//Price   		
	MqlRates _rates[];
	ENUM_TIMEFRAMES _period;

	//Estrategia
	double _maxima;
	double _minima;

	bool _wait;
	int _qtdCopiedRates;

	//Grafico 	   
	color _corBuy;
	color _corSell;
	bool _isDesenhar;
	
	void VerifyStrategy(int order) {

		if (order == ORDER_TYPE_BUY) {

			double _entrada = _maxima + GetSpread();			

			if (GetLastPrice() >= _entrada) {

				if (!HasPositionOpen()) {
					_wait = false;
					Buy(_entrada);
				}

			}

			return;


		}

		if (order == ORDER_TYPE_SELL) {

			double _entrada = _minima - GetSpread();

			if (GetLastPrice() <= _entrada) {

				if (!HasPositionOpen()) {
					_wait = false;
					Sell(_entrada);
				}

			}

			return;

		}

	}

	bool FindCondition() {

		bool isMatch = false;

		if (ArraySize(_rates) > 1) {
			isMatch = true;
			_maxima = _rates[ArraySize(_rates) - 1].high;
			_minima = _rates[ArraySize(_rates) - 1].low;
		}

		if (isMatch) {

			for (int i = ArraySize(_rates) - 1; i >= 0; i--) {

				if (_rates[i].high > _maxima + GetSpread() || _rates[i].low < _minima - GetSpread()) {
					isMatch = false;
				}

				if (GetLastPrice() > _maxima + GetSpread() || GetLastPrice() < _minima - GetSpread()) {
					isMatch = false;
				}

			}

		}

		return isMatch;

	}

	void Draw(double price, color cor)
	{

		if (!_isDesenhar) {
			return;
		}

		string objName = "LINE" + (string)price;
		ObjectCreate(0, objName, OBJ_HLINE, 0, 0, price);

		ObjectSetInteger(0, objName, OBJPROP_COLOR, cor);
		ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrBlack);
		ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
		ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
		ObjectSetInteger(0, objName, OBJPROP_BACK, true);
		ObjectSetInteger(0, objName, OBJPROP_FILL, true);

		//ARROW PRICE
		objName = "SETA" + (string)price;
		ObjectCreate(0, objName, OBJ_ARROW_RIGHT_PRICE, 0, _rates[0].time, price);
		ObjectSetInteger(0, objName, OBJPROP_COLOR, cor);
		ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrBlack);
		ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
		ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
		ObjectSetInteger(0, objName, OBJPROP_BACK, false);
		ObjectSetString(0, objName, OBJPROP_TEXT, "ENTRADA EM " + (string)price);
	}

	void ClearDraw(double price) {

		if (!_isDesenhar) {
			return;
		}

		ObjectDelete(0, "LINE" + (string)price);
		ObjectDelete(0, "SETA" + (string)price);
	}

	bool GetBuffers() {
	
		ZeroMemory(_rates);
		ArraySetAsSeries(_rates, true);
		ArrayFree(_rates);

		MqlDateTime startDate;
		MqlDateTime stopDate;

		TimeCurrent(startDate);
		stopDate = startDate;

		startDate.hour = GetHoraInicio().hour;
		startDate.min = GetHoraInicio().min;
		startDate.sec = 0;

		int copiedRates = CopyRates(GetSymbol(), GetPeriod(), StructToTime(stopDate), StructToTime(startDate), _rates);

		return copiedRates > 0;

	}

public:

	void SetIsDesenhar(bool isDesenhar) {
		_isDesenhar = isDesenhar;
	}

	void SetColorBuy(color cor) {
		_corBuy = cor;
	};

	void SetColorSell(color cor) {
		_corSell = cor;
	};

	void Load() {
      LoadBase();
	};

	void Execute() {

		if(!ExecuteBase()) return;

		if (GetBuffers()) {

			ClearDraw(_maxima);
			ClearDraw(_minima);

			if (_wait || FindCondition()) {
			   
			   _wait = true;
			
				Draw(_minima, _corSell);
				Draw(_maxima, _corBuy);

				VerifyStrategy(ORDER_TYPE_BUY);
				VerifyStrategy(ORDER_TYPE_SELL);
			}

			SetInfo("COMPRA " + (string)_maxima + " VENDA " + (string)_minima);

		}

	};
	
	void ExecuteOnTrade(){
      ExecuteOnTradeBase();
   };

};

