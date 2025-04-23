<?php

class Dice
{
  private $logger;

  function __construct($logger)
  {
    $this->logger = $logger;
  }

  public function roll($rolls)
  {
    $result = [];
    for ($i = 0; $i < $rolls; $i++) {
      $result[] = $this->rollOnce();
    }
    return $result;
  }

  public function rollOnce()
  {
    $result = random_int(1, 6);
    $this->logger->info("Dice rolled!", ['result' => $result]);
    return $result;
  }
}
