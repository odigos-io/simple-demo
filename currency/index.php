<?php
declare(strict_types=1);

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Factory\AppFactory;
use Monolog\Handler\StreamHandler;
use Monolog\Level;
use Monolog\Logger;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\RequestException;

require __DIR__ . '/vendor/autoload.php';
require('dice.php');

$logger = new Logger('currency-server');
$logger->pushHandler(new StreamHandler('php://stdout', Level::Info));

if (PHP_SAPI === 'cli' && function_exists('pcntl_signal')) {
    $shutdown = false;
    pcntl_signal(SIGTERM, function () use (&$shutdown, $logger) {
        $logger->info('Received SIGTERM, shutting down gracefully…');
        $shutdown = true;
    });
}

$app = AppFactory::create();

$app->addErrorMiddleware(true, true, true)->setDefaultErrorHandler(function (
  Request $request,
  Throwable $exception,
  bool $displayErrorDetails
) use ($app) {
  $response = $app->getResponseFactory()->createResponse();
  $response->withHeader('Content-Type', 'application/json')->withStatus(500);
  $response->getBody()->write(json_encode(['error' => $exception->getMessage()]));
  return $response;
});

$app->get('/rate/ping', function (Request $request, Response $response) {
    $response->getBody()->write('pong');
    return $response;
});

$app->get('/rate/{currencyPair}', function (
  Request $request,
  Response $response,
  array $args
) use ($logger) {
  $currencyPair = $args['currencyPair'];
  $logger->info("Got request...", ['currencyPair' => $currencyPair]);

  $parts = explode('-', $currencyPair);
  $currency1 = $parts[0] ?? null;
  $currency2 = $parts[1] ?? null;

  if (!$currency1 || !$currency2) {
    return $response->withStatus(400)->withHeader('Content-Type', 'application/json')
      ->getBody()->write(json_encode(['error' => 'Invalid currency pair']));
  }

  $geoServiceHost = getenv('GEOLOCATION_SERVICE_HOST') ?: '127.0.0.1:8080';
  $client = new Client(['base_uri' => "http://$geoServiceHost"]);

  try {
    $res1 = $client->request('GET', "/location/$currency1", ['headers' => ['Accept' => 'application/json']]);
    $locationInfo1 = json_decode((string) $res1->getBody(), true);

    $res2 = $client->request('GET', "/location/$currency2", ['headers' => ['Accept' => 'application/json']]);
    $locationInfo2 = json_decode((string) $res2->getBody(), true);

    $conversionRate = (new Dice($logger))->rollOnce();
    $logger->info("Got conversion rate for pair:", ['conversionRate' => $conversionRate]);

    $convertedString = sprintf(
      "1 %s %s = %s %s %s",
      $locationInfo1['ticker'],
      $locationInfo1['flag'],
      $conversionRate,
      $locationInfo2['ticker'],
      $locationInfo2['flag']
    );

    $response = $response->withHeader('Content-Type', 'application/json');
    $response->withStatus(200)->getBody()->write(json_encode(
      [
        'conversionRate' => $conversionRate,
        'convertedString' => $convertedString
      ]
    ));

    return $response;
  } catch (RequestException $e) {
    $logger->error("Geolocation call failed", ['message' => $e->getMessage()]);

    $response = $response->withHeader('Content-Type', 'application/json');
    $response->withStatus(502)->getBody()->write(
      json_encode([
        'error' => 'Failed to fetch location data',
        'message' => $e->getMessage()
      ])
    );

    return $response;
  }
});

$app->run();
