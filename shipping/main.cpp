#include "third_party/httplib.h"

#include <cstdlib>
#include <iostream>
#include <sstream>
#include <string>

namespace {

int listen_port() {
  const char *p = std::getenv("PORT");
  if (!p || !*p) {
    return 8080;
  }
  return std::atoi(p);
}

// Deterministic demo quote from catalog id (no external deps).
int shipping_cents_for_product(int product_id) {
  return 299 + (product_id % 7) * 75;
}

}  // namespace

int main() {
  httplib::Server svr;

  svr.Get("/healthz", [](const httplib::Request &, httplib::Response &res) {
    res.set_content("shipping service ok\n", "text/plain");
  });

  svr.Get("/quote", [](const httplib::Request &req, httplib::Response &res) {
    const std::string id_str = req.get_param_value("id");
    if (id_str.empty()) {
      res.status = 400;
      res.set_content(R"({"error":"missing id query parameter"})", "application/json");
      return;
    }

    char *end = nullptr;
    const long id_long = std::strtol(id_str.c_str(), &end, 10);
    if (end == id_str.c_str() || *end != '\0' || id_long < 1 || id_long > 1000000) {
      res.status = 400;
      res.set_content(R"({"error":"invalid id"})", "application/json");
      return;
    }

    const int product_id = static_cast<int>(id_long);
    const int cents = shipping_cents_for_product(product_id);

    std::ostringstream body;
    body << "{\"productId\":" << product_id << ",\"shippingCents\":" << cents
         << ",\"carrier\":\"ground\"}";
    res.set_content(body.str(), "application/json");
  });

  const int port = listen_port();
  std::cout << "shipping listening on 0.0.0.0:" << port << std::endl;
  if (!svr.listen("0.0.0.0", port)) {
    std::cerr << "failed to bind\n";
    return 1;
  }
  return 0;
}
