; Program to interpolate z-level data from WRF output and dump into file_out generated from zlev_interp.cdl
;  -To add z-levels, add to z matrix AND increase bottom_top in zlev_interp.cdl
;
; Joseph B. Zambon
;  jbzambon@fathomscience.com
;  15-March 2023

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

; generate nc output file
system("rm -rf " + file_out)
system("ncgen -o " + file_out + " zlev_interp.cdl")

in = addfile(file_in,"r")                ; define output file
out = addfile(file_out,"w")              ; define input file
z = (/100/)                              ; define z-levels, dimensions must equal bottom_top in CDL file called above

times = wrf_user_list_times(in)          ; get times in the file
ntimes = dimsizes(times)                 ; number of times in the file
levs   = dimsizes(z)                     ; number of z-levels, dimensions must equal bottom_top in CDL file called above

do time = 0,ntimes-1
  do zlev = 0,levs-1
    uvmet  = wrf_user_getvar(in,"uvmet",time) ; u averaged to mass points
    u = uvmet(0,:,:,:)
    v = uvmet(1,:,:,:)
    height  = wrf_user_getvar(in, "z",time)   ; height is our vertical coordinate
    ter = wrf_user_getvar(in, "ter",time)     ; model terrain height (HGT_M, HGT_U, HGT_V)
    ; Conform data to Terrain Height   
    nheight = conform(height,ter,(/1,2/)) ; assuming height is a 3d array and ter is a 2d array
    height = height - nheight

    ; Interpolate U,V to 100 Meters
    u_plane  = wrf_user_intrp3d( u,height,"h", z(zlev),0.,False)
    v_plane  = wrf_user_intrp3d( v,height,"h", z(zlev),0.,False)
    spd = (u_plane*u_plane + v_plane*v_plane)^(0.5)
    r2d = 45.0/atan(1.0)       ; conversion factor (radians to degrees)
    dir = atan2(u_plane,v_plane) * r2d + 180
    out->u_tr_z(time,zlev,:,:) = (/u_plane/)       ; Time, bottom_top, south_north, west_east
    out->v_tr_z(time,zlev,:,:) = (/v_plane/)       ; Time, bottom_top, south_north, west_east
    out->ws_z(time,zlev,:,:)   = (/spd/)           ; Time, bottom_top, south_north, west_east
    out->wd_z(time,zlev,:,:)   = (/dir/)           ; Time, bottom_top, south_north, west_east
  end do ;end lev loop
end do ;end time loop

; Invariant to time, level loops
out->XLAT=in->XLAT
out->XLONG=in->XLONG
out->Times=in->Times
out->LANDMASK=in->LANDMASK
out->z=z
