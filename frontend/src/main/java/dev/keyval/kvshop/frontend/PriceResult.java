package dev.keyval.kvshop.frontend;

public class PriceResult {
    private int id;
    private double price;

    public PriceResult() {
    }

    public PriceResult(int id, double price) {
        this.price = price;
        this.id = id;
    }

    public double getPrice() {
        return price;
    }

    public void setPrice(double price) {
        this.price = price;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }
}
