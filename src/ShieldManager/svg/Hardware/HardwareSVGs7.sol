// SPDX-License-Identifier: The Unlicense
/// @author Modified from Area-Technology (https://github.com/Area-Technology/shields-contracts/tree/main/contracts/SVGs)

pragma solidity ^0.8.13;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs7 is IHardwareSVGs, ICategories {
	function hardware_26() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Jackhammer',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16419.02)" gradientUnits="userSpaceOnUse" id="h26-a" x1="16.56" x2="16.56" y1="16385.2" y2="16398.14"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h26-b" x1="17.98" x2="2.17" xlink:href="#h26-a" y1="16396.59" y2="16414.46"/><linearGradient id="h26-c" x1="9.21" x2="9.21" xlink:href="#h26-a" y1="16418.41" y2="16384.18"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 16428.2)" gradientUnits="userSpaceOnUse" id="h26-d" x1="18.44" x2="18.44" y1="16418.92" y2="16388.8"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><filter id="h26-e" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h26-f" x1="95" x2="125" y1="169.25" y2="169.25"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h26-g" x1="107.84" x2="107.84" xlink:href="#h26-d" y1="112.2" y2="77.15"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h26-h" x1="112.15" x2="112.15" xlink:href="#h26-d" y1="80.05" y2="114.85"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h26-i" x1="110" x2="110" xlink:href="#h26-d" y1="87.8" y2="76.23"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h26-j" x1="105.69" x2="114.31" y1="78.34" y2="78.34"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h26-k" x1="102" x2="105.22" xlink:href="#h26-j" y1="106.72" y2="106.72"/><linearGradient id="h26-l" x1="114.78" x2="118" xlink:href="#h26-j" y1="106.72" y2="106.72"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h26-m" x1="102.41" x2="115.84" y1="108.25" y2="108.25"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h26-n" x1="110" x2="110" xlink:href="#h26-m" y1="106.84" y2="100.41"/><linearGradient id="h26-o" x1="110" x2="110" xlink:href="#h26-j" y1="164.5" y2="157.1"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h26-p" x1="120" x2="100" y1="113.37" y2="113.37"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h26-q" x1="99.82" x2="119.95" xlink:href="#h26-m" y1="120.27" y2="120.27"/><linearGradient id="h26-r" x1="96.46" x2="96.46" xlink:href="#h26-j" y1="173.46" y2="146.48"/><linearGradient id="h26-s" x1="123.53" x2="123.53" xlink:href="#h26-j" y1="173.46" y2="146.48"/><linearGradient id="h26-t" x1="100" x2="120" xlink:href="#h26-f" y1="138.5" y2="138.5"/><linearGradient id="h26-u" x1="100" x2="120" xlink:href="#h26-f" y1="117.5" y2="117.5"/><symbol id="h26-w" viewBox="0 0 18.41 35.02"><path d="M15.75 28.55 18.42 35V22.09L14.7 20.74Z" fill="url(#h26-a)"/><path d="M16.44 22.8 6.63 11.18 0 0 18.42 22.09Z" fill="url(#h26-b)"/><path d="M16.86 28.72 6.55 9.79 0 0 18.42 35Z" fill="url(#h26-c)"/></symbol><symbol id="h26-v" viewBox="0 0 36.84 44.2"><path d="M18.43 24.12 36.84 44.2l-17-23.26-1.44 1.15Zm0 12.93V35L17.8 31 0 .25Z"/><use height="35.02" transform="translate(0.03)" width="18.42" xlink:href="#h26-w"/><use height="35.02" transform="translate(36.85 44.17) rotate(180)" width="18.42" xlink:href="#h26-w"/><path d="M19.44 21.72V13.26l12.13 23ZM5.31 7.9 17.44 22.45V31Z" fill="url(#h26-d)"/></symbol></defs><use height="44.2" transform="translate(66.56 109.91)" width="36.85" xlink:href="#h26-v"/><use height="44.2" transform="translate(66.56 139.91)" width="36.85" xlink:href="#h26-v"/><use height="44.2" transform="matrix(-1 0 0 1 153.44 109.91)" width="36.85" xlink:href="#h26-v"/><use height="44.2" transform="matrix(-1 0 0 1 153.44 139.91)" width="36.85" xlink:href="#h26-v"/><g filter="url(#h26-e)"><path d="M122.07 87.5H97.93l-2.93 3L110 102l15-11.46Z" fill="url(#h26-f)"/><path d="M110 183.21v-33h-2v24.55c0 2.09-2.26 3.06-2.26 5.14v3.33Z" fill="url(#h26-g)"/><path d="M110 183.21v-33h2v24.55c0 2.08 2.27 3.07 2.27 5.14v3.33Z" fill="url(#h26-h)"/><path d="M112 159.66H108v2H112Z"/><path d="M112.15 179.39a4.75 4.75 0 0 1-2.15-3.73 4.8 4.8 0 0 1-2.15 3.73 4.74 4.74 0 0 0-2.16 3.82v3.36h8.62v-3.36A4.77 4.77 0 0 0 112.15 179.39Z" fill="url(#h26-i)"/><path d="M114.31 184.75h-8.62v1.82h8.62Z" fill="url(#h26-j)"/><path d="M105.22 152.57H102V162h3.22Z" fill="url(#h26-k)"/><path d="M114.78 162H118v-9.43h-3.22Z" fill="url(#h26-l)"/><path d="M115.12 151.28l-.92 4.64a2.32 2.32 0 0 1-2.16 1.8H108a2.32 2.32 0 0 1-2.16-1.8l-.92-4.64h-2.61l.94 4.72a5.39 5.39 0 0 0 5.06 4.23h3.46a5.39 5.39 0 0 0 5.06-4.23l.94-4.72Z" fill="url(#h26-m)"/><path d="M146 99.5H74a.7.7 0 0 0-.66.91L74.46 104a.69.69 0 0 0 .66.48H87a2.41 2.41 0 0 1 2.41 2.4h41.25a2.41 2.41 0 0 1 2.41-2.4h11.84a.69.69 0 0 0 .66-.48l1.17-3.61A.69.69 0 0 0 146 99.5Z" fill="url(#h26-n)"/><path d="M92.16 106.9h35.68V99.5H92.16Z" fill="url(#h26-o)"/><path d="M118 152.57H102L100 150l10-1.3 10 1.3Z" fill="url(#h26-p)"/><polygon fill="url(#h26-q)" points="95 90.54 97.93 117.52 99.97 119.97 100 120 100 124 101 125 100 126 100 145 101 146 100 147 100 150 120 150 120 147 119 146 120 145 120 126 119 125 120 124 120 120 122.07 117.52 125 90.54 95 90.54"/><path d="M97.93 90.54H95V114l2.93 3.52Z" fill="url(#h26-r)"/><path d="M122.07 90.54H125V114l-2.93 3.52Z" fill="url(#h26-s)"/><path d="M110 120H100v3.38s2.72-2.38 10-2.38 10 2.38 10 2.38V120Z"/><path d="M120 126H100l1-1h18Z" fill="url(#h26-t)"/><path d="M119 125H101l-1-1h20Z"/><path d="M120 147H100l1-1h18Z" fill="url(#h26-u)"/><path d="M119 146H101l-1-1h20Z"/></g>'
					)
				)
			);
	}

	function hardware_27() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Jewelers Loupe',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><radialGradient cx=".5" cy=".2" id="h27-a" r="1"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><linearGradient gradientUnits="userSpaceOnUse" id="h27-b" x1="3.88" x2="3.88" y2="7.75"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><radialGradient cx=".5" cy=".2" id="h27-c" r="1.25"><stop offset="0" stop-color="#8c8c8c" stop-opacity="0"/><stop offset="0.55" stop-color="#fff" stop-opacity="0.8"/><stop offset="0.64" stop-color="#8c8c8c" stop-opacity="0"/><stop offset="0.76" stop-color="#fff"/></radialGradient><filter id="h27-d" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient id="h27-e" x1="110" x2="110" xlink:href="#h27-b" y1="86.14" y2="132.68"/><linearGradient id="h27-f" x1="110" x2="110" xlink:href="#h27-b" y1="133.21" y2="85.64"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h27-g" x1="110" x2="110" xlink:href="#h27-b" y1="141.5" y2="133.01"/><linearGradient gradientUnits="userSpaceOnUse" id="h27-h" x1="110" x2="110" y1="182.03" y2="117.82"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h27-i" x1="110" x2="110" xlink:href="#h27-b" y1="180.11" y2="120.11"/><linearGradient id="h27-j" x1="110" x2="110" xlink:href="#h27-b" y1="88.21" y2="115.79"/><symbol id="h27-k" viewBox="0 0 7.75 7.75"><path d="M3.88 7.25A3.38 3.38 0 1 0 .5 3.88 3.37 3.37 0 0 0 3.88 7.25Z" fill="url(#h27-a)" stroke="url(#h27-b)"/><path d="M4.38 1.88h-1v4h1Z"/><path d="M1.88 3.38v1h4v-1Z"/></symbol></defs><path d="M110 114.87A12.87 12.87 0 1 0 97.13 102 12.87 12.87 0 0 0 110 114.87Z" fill="url(#h27-c)"/><g filter="url(#h27-d)"><path d="M110 86.14A15.87 15.87 0 0 0 94.14 102c0 10.5 14.14 30.05 15.86 30.68 1.71-.62 15.86-20.18 15.86-30.68A15.88 15.88 0 0 0 110 86.14Zm0 29.15A13.29 13.29 0 1 1 123.29 102 13.3 13.3 0 0 1 110 115.29Z" fill="url(#h27-e)" stroke="url(#h27-f)"/><path d="M110 130.11a4 4 0 1 0-4-4A4 4 0 0 0 110 130.11Z" fill="url(#h27-g)"/><path d="M124.48 140.27l-9.7-16.89a5.5 5.5 0 0 0-9.55 0l-9.7 16.89a17.41 17.41 0 0 0 0 19.64l.17.25.06.16 9.66 16.81a5.51 5.51 0 0 0 9.2 0l9.66-16.81.07-.16.17-.25A17.42 17.42 0 0 0 124.48 140.27Z" fill="url(#h27-h)" stroke="url(#h27-i)"/><use height="7.75" transform="translate(106.12 122.23)" width="7.75" xlink:href="#h27-k"/><use height="7.75" transform="translate(106.12 170.23)" width="7.75" xlink:href="#h27-k"/><circle cx="110" cy="102" fill="none" r="13.29" stroke="url(#h27-j)"/></g>'
					)
				)
			);
	}

	function hardware_28() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Fasces',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16424)" gradientUnits="userSpaceOnUse" id="h28-a" x1="26.02" x2="0" y1="16404" y2="16404"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h28-b" x2="26.02" y1="20" y2="20"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 16387.37)" gradientUnits="userSpaceOnUse" id="h28-c" x2="5" y1="16386.28" y2="16386.28"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h28-d" x1="5" x2="0" xlink:href="#h28-a" y1="32.31" y2="32.31"/><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h28-e" x1="27" x2="0" xlink:href="#h28-a" y1="3.5" y2="3.5"/><linearGradient id="h28-f" x2="27" xlink:href="#h28-b" y1="0.5" y2="0.5"/><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h28-g" x2="27" xlink:href="#h28-c" y1="6.5" y2="6.5"/><filter id="h28-h" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h28-i" x1="104.99" x2="104.99" y1="180.49" y2="159.53"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h28-j" x1="122.5" x2="93.87" xlink:href="#h28-i" y1="177.03" y2="177.03"/><linearGradient id="h28-k" x1="122" x2="122" xlink:href="#h28-i" y1="165" y2="175"/><linearGradient id="h28-l" x1="93.87" x2="122.5" xlink:href="#h28-i" y1="162.97" y2="162.97"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h28-m" x1="90.36" x2="90.36" xlink:href="#h28-b" y1="183.27" y2="156.73"/><symbol id="h28-n" viewBox="0 0 5 2.19"><path d="M4 2.19H1l-1-1L2.5 0 5 1.19Z" fill="url(#h28-c)"/></symbol><symbol id="h28-q" viewBox="0 0 25 2.19"><use height="2.19" transform="translate(15)" width="5" xlink:href="#h28-n"/><use height="2.19" transform="translate(20)" width="5" xlink:href="#h28-n"/><use height="2.19" width="5" xlink:href="#h28-n"/><use height="2.19" transform="translate(5)" width="5" xlink:href="#h28-n"/></symbol><symbol id="h28-aa" viewBox="0 0 5 64.63"><rect fill="url(#h28-d)" height="64.63" width="5"/></symbol><symbol id="h28-af" viewBox="0 0 26.02 43"><path d="M.74 1 25 30l1 1.83v7.63l-1.53-1.1L.7 9.66 0 8.2V.57Z" fill="url(#h28-a)"/><path d="M25.51 39v4c0-2.62-3.63-7.64-5-6 0-2.62-3.68-7.53-5-6 0-1.47-1.57-3.95-3-5.42V23.45ZM8.37 20.54h0l.95.05L.51 9v4c1-.85 5 3.38 5 6C6.52 18.26 8.37 20.54 8.37 20.54Z"/><path d="M.51 0l25 30L26 31.8 0 .57ZM26 39.43 0 8.2.51 10l25 30Z" fill="url(#h28-b)"/></symbol><symbol id="h28-ah" viewBox="0 0 27 7"><path d="M13.5 0 0 1V6L13.5 7 27 6V1Z" fill="url(#h28-e)"/><path d="M26 0H1L0 1H27Z" fill="url(#h28-f)"/><path d="M1 7H26l1-1H0Z" fill="url(#h28-g)"/></symbol><symbol id="h28-aj" viewBox="0 0 25.1 1.8"><path d="M.05 1.8A2.72 2.72 0 0 1 2.55.55 2.72 2.72 0 0 1 5.05 1.8 2.72 2.72 0 0 1 7.55.55a2.72 2.72 0 0 1 2.5 1.25A2.58 2.58 0 0 1 12.55.55a2.58 2.58 0 0 1 2.5 1.25A2.53 2.53 0 0 1 17.55.55a2.53 2.53 0 0 1 2.5 1.25A2.55 2.55 0 0 1 22.55.55a2.55 2.55 0 0 1 2.5 1.25L25.1 0H0Z"/></symbol></defs><g filter="url(#h28-h)"><use height="2.19" transform="translate(107.5 182.05)" width="5" xlink:href="#h28-n"/><use height="2.19" transform="matrix(1 0 0 -1 107.5 86.19)" width="5" xlink:href="#h28-n"/><use height="2.19" transform="translate(102.5 105.5)" width="5" xlink:href="#h28-n"/><use height="2.19" transform="matrix(1 0 0 -1 97.5 107.69)" width="25" xlink:href="#h28-q"/><use height="2.19" transform="translate(97.5 169.94)" width="25" xlink:href="#h28-q"/><use height="64.63" transform="translate(107.5 85) scale(1 1.52)" width="5" xlink:href="#h28-aa"/><use height="64.63" transform="translate(97.5 106.5)" width="5" xlink:href="#h28-aa"/><use height="64.63" transform="translate(102.5 106.5)" width="5" xlink:href="#h28-aa"/><use height="64.63" transform="translate(112.5 106.5)" width="5" xlink:href="#h28-aa"/><use height="64.63" transform="translate(117.5 106.5)" width="5" xlink:href="#h28-aa"/><use height="43" transform="matrix(-1 0 0 1 123.01 119)" width="26.02" xlink:href="#h28-af"/><use height="43" transform="translate(96.99 119)" width="26.02" xlink:href="#h28-af"/><use height="7" transform="translate(96.5 161)" width="27" xlink:href="#h28-ah"/><path d="M101.47 89.31c-5 0-7.6-5.36-7.6-5.36C92.23 82.46 88 84.52 88 94s4.13 11.5 5.88 10c0 0 2.49-5.36 7.6-5.36H122V89.31Z" fill="url(#h28-i)"/><path d="M121.5 90h-19c-6 0-8.63-6-8.63-6 1.7 2.32 4.55 5 8.63 5h20Z" fill="url(#h28-j)"/><path d="M122.5 99l-1-1V90l1-1Z" fill="url(#h28-k)"/><path d="M121.5 98h-19c-6 0-8.63 6-8.63 6 1.7-2.32 4.55-5 8.63-5h20Z" fill="url(#h28-l)"/><path d="M90.65 94a16.17 16.17 0 0 1 3.22-10L92 80.73S86.86 84.52 86.86 94 92 107.27 92 107.27l1.87-3.22A16.17 16.17 0 0 1 90.65 94Z" fill="url(#h28-m)"/><use height="7" transform="translate(96.5 109.5)" width="27" xlink:href="#h28-ah"/></g><polygon points="112.5 100 107.5 100 102.5 99 122.5 99 112.5 100"/><use height="1.8" transform="translate(97.45 167.95)" width="25.1" xlink:href="#h28-aj"/><use height="1.8" transform="translate(97.45 116.45)" width="25.1" xlink:href="#h28-aj"/>'
					)
				)
			);
	}

	function hardware_29() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Cauldron',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><filter id="h29-a" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientUnits="userSpaceOnUse" id="h29-b" x1="80.34" x2="139.65" y1="120.51" y2="120.51"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><radialGradient cx="110" cy="161.61" gradientUnits="userSpaceOnUse" id="h29-c" r="51.35"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></radialGradient><linearGradient gradientTransform="matrix(1 0 0 -1 -335.2 -164.3)" gradientUnits="userSpaceOnUse" id="h29-d" x1="445.2" x2="445.2" y1="-252.7" y2="-282.14"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h29-e" x1="81.03" x2="138.97" y1="101.72" y2="101.72"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><radialGradient cx="110" cy="121.86" id="h29-f" r="70.46" xlink:href="#h29-c"/><linearGradient gradientTransform="matrix(1 0 0 -1 -335.2 -164.3)" id="h29-g" x1="466.42" x2="470.2" xlink:href="#h29-e" y1="-278.92" y2="-278.92"/><linearGradient gradientTransform="matrix(1 0 0 -1 -256 -82)" id="h29-h" x1="336.35" x2="395.65" xlink:href="#h29-e" y1="-200.47" y2="-200.47"/><linearGradient id="h29-i" x1="92.83" x2="127.17" xlink:href="#h29-b" y1="132" y2="132"/><linearGradient gradientTransform="translate(555.2 -164.3) rotate(180)" id="h29-j" x1="466.42" x2="470.2" xlink:href="#h29-e" y1="-278.92" y2="-278.92"/></defs><g filter="url(#h29-a)"><rect fill="url(#h29-b)" height="3.08" width="59.31" x="80.34" y="118.97"/><path d="M80.34 122.05s11.89 5.66 12.8 10.34h33.72c.91-4.68 12.8-10.34 12.8-10.34Z" fill="url(#h29-c)"/><path d="M135 107.05c4.78 0 4.75 8-.91 8-9.62 0-5.21-26.65-24.09-26.65s-14.47 26.65-24.09 26.65c-5.66 0-5.69-8-.91-8-2.48-1.06-5.8 1.08-5.8 4.79 0 3 2 6 7.44 6 12.51 0 7.42-24.66 23.36-24.66s10.85 24.66 23.36 24.66c5.47 0 7.44-3.06 7.44-6C140.8 108.13 137.48 106 135 107.05Z" fill="url(#h29-d)"/><path d="M135 107.05c4.78 0 4.75 8-.91 8-9.62 0-5.21-26.65-24.09-26.65s-14.47 26.65-24.09 26.65c-5.66 0-5.69-8-.91-8" fill="none" stroke="url(#h29-e)"/><path d="M126.86 132.39H93.14a20.62 20.62 0 0 0-13.57 19.66c0 17.39 15.43 30 30.43 30s30.43-12.61 30.43-30A20.62 20.62 0 0 0 126.86 132.39Z" fill="url(#h29-f)"/><path d="M133.11 110.27h0a1.89 1.89 0 0 0-1.89 1.89V119H135v-6.81A1.89 1.89 0 0 0 133.11 110.27Z" fill="url(#h29-g)"/><polygon fill="url(#h29-h)" points="81.35 117.97 80.35 118.97 139.65 118.97 138.65 117.97 81.35 117.97"/><line fill="none" stroke="url(#h29-i)" x1="127.17" x2="92.83" y1="132" y2="132"/><path d="M86.89 110.27h0a1.89 1.89 0 0 1 1.89 1.89V119H85v-6.81A1.89 1.89 0 0 1 86.89 110.27Z" fill="url(#h29-j)"/></g>'
					)
				)
			);
	}
}
