#  Shazam Clone - User Guide

This project is a robust audio identification system developed in MATLAB, capable of indexing music libraries and recognizing audio fragments even under extreme noise conditions.

---

###  1. Environment Setup
Before running the application, organize your files so the system can locate them automatically:

* **Audio Folder**: Create a folder named `Songs` in the project's root directory.
* **MP3 Files**: Add all the songs you want the system to recognize into that folder.
* **Scripts**: Ensure all `.m` files (including the noise engine and visualization tools) are in the same directory as the main controller.

---

###  2. System Execution
The workflow is fully automated through the central controller for ease of use.

1. **Open MATLAB** and navigate to the project folder.
2. **Run the `main.m` script**.
3. **Intelligent Detection**: The system will automatically check for the existence of the `shazam_db.mat` database file:
    * **If it does not exist**: The **Indexing** process will start to populate your `Songs` folder data.
    * **If it already exists**: The system will skip directly to the **Identification (Matching)** phase.

---

###  3. Internal Workflow

####  Indexing Phase (Automated)
* **Processing**: Each song is normalized and converted to mono before generating its spectrogram.
* **Landmarking**: High-energy points are extracted using a dynamic threshold based on the signal's mean and standard deviation.
* **Hashing**: Peak pairs (*Fan-out*) are created and packed into 32-bit keys using bitwise arithmetic for ultra-fast searching.

####  Identification Phase (Matching)
* **Selection**: A pop-up window will appear for you to select the audio file you wish to identify.
* **Stress Test**: The system clips a **5-second** fragment and applies **50% impulsive noise** to test the algorithm's robustness.
* **Statistical Voting**: The engine searches for matches and uses the **Mode** of time offsets to find the winning song, effectively ignoring random noise.

---

###  4. Results Visualization
Once the analysis is complete, the system automatically generates:
1. **Console Report**: Displays the identified song name, confidence score (votes), and total response time.
2. **Fingerprint Capture**: A plot is displayed overlaying the **Landmarks** (red dots) on the noisy fragment's spectrogram to visually validate the detection.
