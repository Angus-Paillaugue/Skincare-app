android-launch-staging:
	flutter run --flavor staging
android-launch-production:
	flutter run --flavor production
android-build-staging:
	flutter build apk --flavor staging
android-build-production:
	flutter build apk --flavor production
android-install-staging:
	flutter install --flavor staging
android-install-production:
	flutter install --flavor production
android-publish-staging:
	flutter build appbundle --flavor staging
	flutter pub run flutter_launcher_icons:main
android-publish-production:
	flutter build appbundle --flavor production
	flutter pub run flutter_launcher_icons:main
