// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';

const APP_NAME = 'URCLINIC';
const APP_LOGO_URL = '$DOMAIN_URL/img/logo/mini_logo.png';
const DEFAULT_LANGUAGE = 'en';
const FIREBASE_SERVER_CLIENT_ID = "YOUR_FIREBASE_SERVER_CLIENT_ID";

///Live Url
const DOMAIN_URL = "https://urclinic.findosystem.com";

const BASE_URL = '$DOMAIN_URL/api/';

const APP_PLAY_STORE_URL = '';
const APP_APPSTORE_URL = '';

const TERMS_CONDITION_URL = '$DOMAIN_URL/page/terms-conditions';
const PRIVACY_POLICY_URL = '$DOMAIN_URL/page/privacy-policy';
const INQUIRY_SUPPORT_EMAIL = 'findogroup5@gmail.com';

/// You can add help line number here for contact. It's demo number
const HELP_LINE_NUMBER = '+15265897485';

//region Payment Gateway
//region STRIPE
const STRIPE_URL = 'https://api.stripe.com/v1/payment_intents';
const STRIPE_merchantIdentifier = "merchant.flutter.stripe.test";
const STRIPE_CURRENCY_CODE = 'INR';
//endregion

/// PAYSTACK
const String payStackCurrency = "NGN";

/// PAYPAl
const String payPalSupportedCurrency = 'USD';

/// Airtel Money Payments
///It Supports ["UGX", "NGN", "TZS", "KES", "RWF", "ZMW", "CFA", "XOF", "XAF", "CDF", "USD", "XAF", "SCR", "MGA", "MWK"]
const airtel_currency_code = "MWK";
const airtel_country_code = "MW";
const AIRTEL_BASE = kDebugMode
    ? 'https://openapiuat.airtel.africa/'
    : "https://openapi.airtel.africa";

/// SADAD PAYMENT DETAIL
const SADAD_API_URL = 'https://api-s.sadad.qa';
const SADAD_PAY_URL = "https://d.sadad.qa";

//end region
