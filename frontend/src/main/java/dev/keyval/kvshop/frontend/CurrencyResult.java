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

    public String getCurrencyPair() {
        return currencyPair;
    }

    public int getConversionRate() {
        return conversionRate;
    }

}
