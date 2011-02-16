<?php
/** 
  * AquaticPrime PHP Config
  * Configuration for web server license generation
  * @author Lucas Newman, Aquatic
  * @copyright Copyright &copy; 2005 Lucas Newman
  * @license http://www.opensource.org/licenses/bsd-license.php BSD License
  */

// ----CONFIG----

// When pasting keys here, don't include the leading "0x" that AquaticPrime Developer adds.
$key = "EEB979021E1655372F62B9DC24A928D6E290BB381A976903A1EE165F4AEBE17FF0D1B9D6A61DF0DBB82F1DD6878B4BDCBAA48CEB78F16701C43CC1C334E9A04BC88641AD5FE8A42631A4CD88AE2701679CACA9C735B968165210252CFDA7D336A3B77325BE3636F6D146F4091EF2EF2B08F8C451ED0AA8C800C6042AA23FF2F5";
$privateKey = "9F2650AC140EE37A1F972692C31B708F41B5D225670F9B57C149643F8747EBAAA08BD139C413F5E7D01F6939AFB2329327185DF250A0EF5682D32BD7789BC0313C1070C6C6B65036948B0E677250039E1BD58C1CD205B1687A16F617A1B88AE8D2244EDB00E8E584E0F09479CABB4167D6EAC1D1EB78C67E9316D47B70522DB3";

$domain = "mugginsoft.com";
$product = "KosmicTask";
$download = "http://www.$domain/sites/mugginsoft.com/files/download/KosmicTask.zip";

// These fields below should be customized for your application.  You can use ##NAME## in place of the customer's name and ##EMAIL## in place of his/her email
$from = "support@$domain";
$subject = "$product License For ##NAME##";
$message =
"Hello ##NAME##!  Here's your license for $product.

If you have not already downloaded $product please do so now: <$download>

---YOUR INSTALL INSTRUCTIONS--- to register $product.

Thanks,

Jonathan Mitchell

Developer
Mugginsoft LLP";

// It's a good idea to BCC your own email here so you can have an order history
$bcc = "licence-code@$domain";

// This is the name of the license file that will be attached to the email
$licenseName = "##NAME##.ktlic";


// ---PAYPAL ONLY CONFIG----

// Your PDT authorization token
$auth_token = "AUTH TOKEN HERE";
// Put in a URL here to redirect back to after the transaction
$redirect_url = "http://$domain/thanks.html";
$error_url = "http://$domain/error.html";
?>
