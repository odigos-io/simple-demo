package dev.keyval.kvshop.frontend;

public class CurrencyResult {
    private int currency;

    public CurrencyResult() {
    }

    public CurrencyResult(int currency) {
        this.currency = currency;
    }

    public int getUsdIlsConversion() {
        return currency;
    }
}
