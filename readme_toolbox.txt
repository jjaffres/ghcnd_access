readme.txt file for extraction of Global Historical Climatology Network - Daily (GHCN-Daily) data

--------------------------------------------------------------------------------
Program: ghcnd_access.m
Article: GHCN-Daily: a treasure trove of climate data awaiting discovery
Author:  Jasmine B. D. Jaffrés

To acknowledge the use of this program, please cite:
Jaffrés, J.B.D. (2019) GHCN-Daily: a treasure trove of climate data awaiting discovery. Computers & Geosciences 122, 35-44.
--------------------------------------------------------------------------------


Requirements
------------
This toolbox can be run in either GNU Octave or MATLAB. In the assumption that all available capabilities at the time of testing the script are maintained, the toobox will work in versions

- GNU Octave v4.2.0 or newer
- MATLAB R2014a or newer


Summary of Procedure [ for details, please consult "User's Guide (GHCN-Daily data access).pdf" ]
-------------------------------------------------------------------------------------------------

1) Ensure that you have downloaded all relevant GHCN-Daily data and that these are located here:
	.\ghcnd_access\data

2) Open the ghcnd_access.m file

3) Modify ghcnd_access.m according to your file extraction requirements and run the script

4) By default, all data while be compiled in .mat files. If you requested daily data and prefer the data in Excel format, open .\ghcnd_access\postproc\dailypostproc.m to convert the .mat output into .xlsx

5) Modify dailypostproc.m according to your required data type and run the script


Disclaimer
-------------------------------------------------------------------------------------------------
You can redistribute this script and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This script is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.