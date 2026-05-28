import numpy as np
import xarray as xr

los1 = xr.open_dataset("rs64.grd") 
los2 = xr.open_dataset("rs71.grd")  
los3 = xr.open_dataset("rs144.grd")  

d1, d2, d3 = los1["z"].values, los2["z"].values, los3["z"].values
lon = los1["lon"].values
lat = los1["lat"].values

looke1, lookn1, looku1 = -0.642905, -0.112016, 0.757612 # asc t64
looke2, lookn2, looku2 = 0.691407, -0.114493, 0.713219 # des T71
looke3, lookn3, looku3 = 0.54795, -0.103284, 0.829954 # des T144

A = np.array([
    [looke1, looku1],
    [looke2, looku2],
    [looke3, looku3]
])

d_los = np.stack([d1, d2, d3], axis=-1)  # Shape: (lon, lat, 3)

mask = np.any(np.isnan(d_los), axis=-1)
d_ew = np.full_like(d1, np.nan)
d_up = np.full_like(d1, np.nan)

valid_points = ~mask
reshaped_los = d_los[valid_points]  # Extract valid LOS values
if reshaped_los.shape[0] > 0:  # Check if there are valid points to solve
    result = np.linalg.lstsq(A, reshaped_los.T, rcond=None)[0]  
    d_ew[valid_points], d_up[valid_points] = result[0], result[1]

d_ew_xr = xr.DataArray(d_ew, coords=[("lat", lat), ("lon", lon)], dims=["lat", "lon"], name="z")
d_up_xr = xr.DataArray(d_up, coords=[("lat", lat), ("lon", lon)], dims=["lat", "lon"], name="z")

d_ew_xr.to_netcdf("east_west.grd")
d_up_xr.to_netcdf("up_down.grd")