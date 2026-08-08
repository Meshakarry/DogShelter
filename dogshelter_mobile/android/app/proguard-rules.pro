# flutter_stripe's Android SDK includes an optional push-provisioning (Google Pay Tap-to-Pay
# card issuing) module this app doesn't use. R8 can't resolve its Google Play Services
# dependency (play-services-tapandpay), so these classes must be excluded from analysis.
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
