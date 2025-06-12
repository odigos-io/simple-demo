package dev.keyval.kvshop.frontend;

import com.fasterxml.jackson.annotation.JsonProperty;

public class CurrencyResult {
    @JsonProperty("currencyPair")
    private String currencyPair;

    @JsonProperty("conversionRate")
    private int conversionRate;

    @JsonProperty("convertedString")
    private String convertedString;

    public CurrencyResult() {
        // Default constructor for deserialization
    }

    public CurrencyResult(String currencyPair, int conversionRate, String convertedString) {
        // Constructor for initialization
        this.currencyPair = currencyPair;
        this.conversionRate = conversionRate;
        this.convertedString = convertedString;
    }

    public void setCurrencyPair(String currencyPair) {
        this.currencyPair = currencyPair;
    }

    public void setConversionRate(int conversionRate) {
        this.conversionRate = conversionRate;
    }

    public void setConvertedString(String convertedString) {
        this.convertedString = convertedString;
    }

    public String getCurrencyPair() {
        return currencyPair;
    }

    public int getConversionRate() {
        return conversionRate;
    }

    public String getConvertedString() {
        return convertedString;
    }
}
