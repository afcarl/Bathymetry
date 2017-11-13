# Features
        names = ['long','lat','depth','sigma_h','sigma_d','source_id','pred_depth','dens20', 'dens60','gravity','age','rate','sed thick', 'roughness']

This is the feature names array in the python script that I'm running.

---
## This section describes the columns in sample.cm in the respective order the columns are list in `sample.cm`.
## long

Pretty much as the name suggests, it is the longitude of the data collected.

## lat

Latitude of where the data was collected.

## depth

This is the measured depth.

## sigma_h

Like in statistics, this sigma stands for the horizontal standard deviation.

## sigma_d

A placeholder, feature. We use this column to store the bad data flag.

## source_id

This is the assigned id for the ship's cruise, this will probably make a good key for the sql db..

## pred_depth

This is the predicted depth using an algorithm. The seafloor depth based on a combination of depth predictions from gravity and the measured depth from a previous iteration from the model.

---
## Everything below is added by data extracted from various grd files.
## dens20/dens60

The data density filtered over 10 and 30km half wavelengths.

## gravity

The vertical gravity gradient based on satellite altimetry. Show small scale structures on the seafloor.

## age

This is the age of the seafloor.

## rate

Spreading rate based on the age grid above.

## sed thickness

This is the floor's sediment thickness. Areas of thick sediment have a flat seafloor.

## roughness

This is a measure of how rough the seafloor is. High pass filtered topography at 80km half wavelength squared and low pass filtered at 80km square rooted.
