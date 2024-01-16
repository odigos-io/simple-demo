package dev.keyval.kvshop.frontend;

public class Product {
    private int id;
    private String name;
    private double price;
    private String image;

    public Product() {
        this.id = 0;
        this.name = "";
        this.price = 0.0;
        this.image = "";
    }
    public Product(int id, String name, double price, String image) {
        this.id = id;
        this.name = name;
        this.price = price;
        this.image = image;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public double getPrice() {
        return price;
    }

    public void setPrice(double price) {
        this.price = price;
    }

    public String getImage() {
        return image;
    }

    public void setImage(String image) {
        this.image = image;
    }
}
