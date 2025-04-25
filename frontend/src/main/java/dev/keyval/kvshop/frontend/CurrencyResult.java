package dev.keyval.kvshop.frontend;

import com.fasterxml.jackson.annotation.JsonProperty;

public class CurrencyResult {
    @JsonProperty("currencyPair")
    private String currencyPair;

    @JsonProperty("conversionRate")
    private int conversionRate;

    public CurrencyResult() {
        // Default constructor for deserialization
    }

    public CurrencyResult(String currencyPair, int conversionRate) {
        // Constructor for initialization
        this.currencyPair = currencyPair;
        this.conversionRate = conversionRate;
    }

    public void setCurrencyPair(String currencyPair) {
        this.currencyPair = currencyPair;
    }

    public String getCurrencyPair() {
        return currencyPair;
    }

    public void setConversionRate(int conversionRate) {
        this.conversionRate = conversionRate;
    }

    public int getConversionRate() {
        return conversionRate;
    }
}
