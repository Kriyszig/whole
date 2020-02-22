# Whole

Making roads of Goa Whole again. This project was developed during the Internal hackathon for SIH-2020 held at PES University.  
This application was designed as a solution to the problem statement put forth by Government of Goa titled [Pothole Challenge](https://www.sih.gov.in/sih2020PS/QWxs/QWxs/R292dCBvZiBHb2E=/QWxs). Essentially, this apps allows users to report potholes by placing markers on a map of Goa rendered using Google Maps. A report consists of headline, description and a photographic evidence of the problem. These information are stored in Firebase's Cloud Firestore and the images are uploaded to Firebase Storage. Clicking on pre-existing markers will show you a list of complaints related to the given pothole in a format similar to Instagram feed. Once logged in, an authority can close an issue giving a closing remark. If a report was prematurely closed, users can seek to re-open the issue and with 10 votes, the issue can be opened again.

### Building the project

To build the project, first clone this repository and switch to the working directory

```bash
git clone https://github.com/Kriyszig/whole.git
cd whole
```

To connect to Firebase services, paste the `google-service.json` you download from the Firebase console in `android/app/` directory. To use Google MAps, you will need to add the Google Maps SDK API key obtained from Google Cloud console in `android/app/src/main/AndroidManifest.xml` as

```xml
<meta-data
    android:name="flutterEmbedding"
    android:value="2" />
<!-- Add the below meta tag with your API key as android:value  -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="Masdfgsfg34t353wq4arwsr45tert43r34e5sts"/>
```

To build the flutter app start an android emulator or connect a debugging device and run

```bash
flutter doctor
flutter pub get
flutter run
```

To install Flutter, please go through the official Flutter installation guide [here](https://flutter.dev/docs/get-started/install)

#### Firestore Structure

The structure of Firebase FireStore is as follows:

There are two collections:
* markershack
* reportshack

markershack contains all the details to render the marker on the Google Maps and is structured as follows
```
markershack -> document[documentId: `${latitude}_${longitude}`] -> {
    count,
    latitude,
    longitude,
    status
}
```
The fields are described as follows:
* latitude: Latitude of the reported area
* longitude: Longitude of the reported area
* status: Boolean telling whether the issue is open or close
* count: Number of people who have submitted a re-open compliant for premature issue closure

reportshack contains the postes related to the reported issues and is structured as follows
```
markershack -> document[documentId: `${latitude}_${longitude}`] -> {
    title: [
        description,
        imageURL
    ]
}
```
Each entry is a JSON object with the following property:
* Key is the title of the given issue
* Each value is an array of size 2 - The first field being the description of the issue, and the second field containing the URL of the uploaded image. The second field will be an empty string if no image was uploaded while reporting.



#### Acknowledgement

This prototype would not have been possible if not for the people behind it:
* [Arjun M.](https://github.com/arjun120)
* [Devika S Nair]()
* [Harish S.](https://github.com/Sykarius)
* [Prathima B.](https://github.com/prathima-b)
* [Ruthwik H. M.](https://github.com/RuthwikHM)

This project is nowhere close to ready. It was built in a span of less than 12 hours. There are some known bugs. There are bugs not yet found. Some components are not connected to the Database. This isn't ready in anyway but is nonetheless a blueprint for apps that may require Google Maps integration, Firebase integration and as an application to file reports.
