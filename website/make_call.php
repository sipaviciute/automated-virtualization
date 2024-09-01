<?php

require_once __DIR__ . '/vendor/autoload.php';

use Twilio\Rest\Client;

$accountSid = "AC62b9b7ebda7748c284562396f4ef7335";
$authToken = "42cb7470d9508abf0cef2abf3d4b2f96";

$twilio = new Client($accountSid, $authToken);

$toPhoneNumber = $_POST['phoneNumber'];

$toPhoneNumber = validateAndFormatPhoneNumber($toPhoneNumber);

$call = $twilio->calls
    ->create(
        $toPhoneNumber,
        "+18052840465",
        ["url" => "https://demo.twilio.com/docs/voice.xml"]
    );

echo $call->sid;

function validateAndFormatPhoneNumber($phoneNumber)
{
    if (strpos($phoneNumber, '+') !== 0) {
        $phoneNumber = '+' . $phoneNumber;
    }

    $phoneNumber = preg_replace('/[^\d]/', '', $phoneNumber);

    return $phoneNumber;
}

?>