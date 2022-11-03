// SPDX-License-Identifier: The Unlicense
/// @author Modified from Area-Technology (https://github.com/Area-Technology/shields-contracts/tree/main/contracts/SVGs)

pragma solidity ^0.8.13;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs16 is IHardwareSVGs, ICategories {
	function hardware_61() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Scyths Saltire and Treestump',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h61-a" x1="68.83" x2="78.04" y1="16.58" y2="32.82"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h61-b" x1="2.17" x2="0.19" xlink:href="#h61-a" y1="70.92" y2="69.29"/><linearGradient gradientTransform="matrix(-1 0 0 1 16435.09 -26.28)" gradientUnits="userSpaceOnUse" id="h61-c" x1="16405.81" x2="16407.89" y1="65.85" y2="64.12"><stop offset="0" stop-color="#fff"/><stop offset="0.24" stop-color="gray"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h61-d" x1="75.24" x2="62.67" xlink:href="#h61-a" y1="28.04" y2="8.83"/><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h61-e" x1="7.2" x2="9.7" xlink:href="#h61-c" y1="70.16" y2="68.66"/><linearGradient gradientUnits="userSpaceOnUse" id="h61-f" x1="9.98" x2="9.98" y1="66.65" y2="66.65"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="gray"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h61-g" x1="56.61" x2="54.21" xlink:href="#h61-a" y1="5.78" y2="3.8"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 16455.11)" id="h61-h" x1="54.45" x2="56.99" xlink:href="#h61-f" y1="16451.13" y2="16449.01"/><filter id="h61-i" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientUnits="userSpaceOnUse" id="h61-j" x1="110.88" x2="110.88" y1="142.01" y2="179.83"><stop offset="0"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h61-k" x1="90.25" x2="128.23" y1="156.97" y2="156.97"><stop offset="0" stop-color="#fff"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h61-l" x1="126.85" x2="123.45" y1="150.57" y2="144.36"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h61-m" x1="128.99" x2="128.99" xlink:href="#h61-a" y1="121.59" y2="117.8"/><linearGradient id="h61-n" x1="123.91" x2="98.77" xlink:href="#h61-a" y1="132" y2="132"/><linearGradient id="h61-o" x1="110" x2="110" xlink:href="#h61-a" y1="129.47" y2="133.09"/><symbol id="h61-p" viewBox="0 0 81.94 73.95"><path d="M62.13 2.59C60.24.71 59.5 0 59.5 0L57 2.47l1.12 1.34A1.3 1.3 0 0 1 60.26 5.1l-.43 1.06s14 14.27 22.11 40C78.8 17.06 62.13 2.59 62.13 2.59Z" fill="url(#h61-a)"/><polygon fill="url(#h61-b)" points="0 70.39 1.83 72.08 2.39 71.88 2.5 69.74 0.12 69.74 0 70.39"/><path d="M55.82 7.16 2.39 71.88.12 69.74l54-64.19Z" fill="url(#h61-c)"/><path d="M59.83 6.16l-.92 2.95c4.4 2.43 17.06 18.26 23 37.08C75.32 16.45 59.83 6.16 59.83 6.16ZM59.5.5V0s.74.71 2.63 2.59c0 0 12.77 11.08 18.06 33.36h0C76.45 24.07 72.14 12.62 59.5.5Z" fill="url(#h61-d)"/><path d="M5.94 67.57l3.79 6.3c1 .39 1.88-.89 1.88-.89 0-1.06-3.45-4.47-3.61-8.07A1.71 1.71 0 0 0 5.94 67.57Z" fill="url(#h61-e)"/><path d="M10 66.65" fill="url(#h61-f)"/><polygon fill="url(#h61-g)" points="56.45 2.01 55.89 2.21 53.16 5.59 53.04 6.23 55.33 8.36 55.89 8.16 58.61 4.78 58.73 4.13 56.45 2.01"/><path d="M55.89 2.21 53.16 5.59l2.73 2.57 2.72-3.38Z" fill="url(#h61-h)"/></symbol></defs><path d="M139.69 173.36a32.76 32.76 0 0 0-4.19-.55 6.14 6.14 0 0 1-2.54-1.42c2.76-.91 3.58-2.07 3.7-3.31C124.15 171.77 124 163.26 124 159v-3l5.73-6.12c1.23-1.8-1.58-3.49-1.58-3.49l-27.31-4.3s2.19 27.14-17.52 25.91c1.51 1 3.06 3.63 4.62 3.85-1.89 1-4.29 0-5.9 1.93 3.74-1.41 7.42.69 10-.13-.54 1.77-1.23 1.52-2.1 3.27 5.43-3.34 7.24-7.7 10-8.94-1.92 5-4.28 8.09-8.52 12.2 2.24-.73 5.81-.8 7.91-2.57l-.32 3.68c6.21-4.38 4.06-6.47 7.1-8.9 0 0 .9 6-2.91 10.11 3-1.49 4.53-1 6.7-3.65 1.84 2.72 6 3 6 3-4.34-7.49-4.55-10.52-4.15-15 3.51 2.35 2.2 11.28 10.42 15.12h0c-1.11-1.51-2.94-1.82-3.26-3.2 2.52 1.27 7.32 1.2 9.46 1.53-5.82-3.07-8.31-7.87-9.38-13.34 2.09 3.55 6.65 8.58 10.89 10.08-.59-1.52-1-1-1.36-2.4C132.49 175.84 137.1 173.91 139.69 173.36Zm-21.64 5Z"/><g filter="url(#h61-i)"><use height="73.95" transform="translate(72.48 80.27)" width="81.94" xlink:href="#h61-p"/><path d="M108.55 107.13l-1 1.33a2 2 0 0 1 1.5 2.28c1.38-1.43 1.36-1.45 1.36-1.45Z"/><use height="73.95" transform="matrix(-1 0 0 1 147.52 80.27)" width="81.94" xlink:href="#h61-p"/></g><path d="M103.3 182.51c3.81-4.1 2.91-12.11 2.91-12.11-3 2.43-.89 6.52-7.1 10.9l1.66-7c-1.35 1.89-6.43 4.95-9.25 5.88 6-4.75 9.06-14.44 9.06-14.44-3.13.57-4.79 7.63-10.57 11.18l4-6.11c-2.5 1.89-7.19 1.19-11.92 3A48.28 48.28 0 0 1 88.81 170a10.13 10.13 0 0 1-5.47-2c7.72-1 16-3.17 16-14.84.25-6 21.21-5.44 21.21.9 0 9.78 6.34 18.09 16.12 14-.13 1.37-1 2.65-4.5 3.59 1.66 1.31 4.63.86 7.53 1.7a24.06 24.06 0 0 1-11.81-1c-.11 1.66 1.57 2.65 2.11 4.61-5.72-2-12.05-14.15-12.05-14.15s.84 12.92 10.54 17.41c-2.84-.43-8.6-1.93-10.43-3.87l4.23 5.54c-8.94-4.18-6.54-16.88-11.4-17.64-3.85-.61.08 11.52 5.13 17.53 0 0-4.17-2.24-6-5A18.75 18.75 0 0 1 103.3 182.51Z" fill="url(#h61-j)"/><path d="M105.56 180.35c2-3.86 1.73-8.86 1.84-12.43 0-1.54-1.52-1.93-2.56.74-1.14 2.94-2.21 9-5.73 12.64l.56-7.55-8.15 6.44c5.91-5.73 8.18-13.4 10.67-19.93.58-1.52.32-1.94-1.74.56-4.48 5.39-5 10.58-10.44 16.11a27.49 27.49 0 0 0 2.73-7.52c-2.69 1.94-8 2.87-10.68 4.38 2.43-2.84 6.75-3.76 8.22-5.57-2.19.08-4.83.57-6.94-.21 4.52-.43 12.53-1.57 12.53-13.94l0-22.07h28.2s-.08 21.11-.08 25c0 4.29.13 14.8 12.64 11.11-1 1.23-2.74 2.92-5.34 1.76 1.82 2.47 5.26 3.23 8.37 3.53a15.79 15.79 0 0 1-11.44-2.46A27.86 27.86 0 0 0 130 177a79.66 79.66 0 0 1-8.22-13.34c-.71-1.4-4.09-.65-2.86 2.74 1.89 5.24 3.76 10.79 9.56 13.86-3.43-1.23-6.73-2.58-8.31-5.34-1 2.62.31 4.53 2.12 7-6.68-6.08-4.45-11.83-7-19.93-.87-2.78-3-1.14-3.18.35-.61 5.15-1.23 10.6 3.91 19.47a61.39 61.39 0 0 1-5.71-6.93C108.82 177.32 107.94 179 105.56 180.35Z" fill="url(#h61-k)"/><path d="M124 154c-2.08.65-3.81-3.95 0-9l4.19-2.91 1.55 5.78Z" fill="url(#h61-l)"/><path d="M128.2 142.11c-1 .32.42 6.37 1.55 5.78S129.21 141.8 128.2 142.11Z" fill="url(#h61-m)"/><path d="M110 134.15c-6.43 0-14.1-.37-14.1-2.15s7.67-2.15 14.1-2.15 14.11.37 14.11 2.15S116.43 134.15 110 134.15Z" fill="url(#h61-n)"/><path d="M110 129.44c-9.21 0-13.82 1.15-13.82 2s4.61 2 13.82 2 13.82-1.15 13.82-2S119.21 129.44 110 129.44Z" fill="url(#h61-o)"/>'
					)
				)
			);
	}

	function hardware_62() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Mining Helmet and Picks Saltire',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="matrix(1 0 0 -1 1.38 16454.78)" gradientUnits="userSpaceOnUse" id="h62-a" x1="-1.73" x2="3.62" y1="16372.13" y2="16372.13"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 1.38 16454.78)" gradientUnits="userSpaceOnUse" id="h62-b" x1="30.93" x2="35.58" y1="16413.52" y2="16409.65"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 1.38 16454.78)" gradientUnits="userSpaceOnUse" id="h62-c" x1="35.9" x2="75.8" y1="16438.13" y2="16438.13"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(0.77 0.64 -0.64 0.77 7194.27 -3351.67)" gradientUnits="userSpaceOnUse" id="h62-d" x1="-3326.18" x2="-3326.18" y1="7150.26" y2="7155.98"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 1.38 16454.78)" gradientUnits="userSpaceOnUse" id="h62-e" x1="59.46" x2="59.46" y1="16450.71" y2="16434.14"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h62-f" x1="57.48" x2="57.48" xlink:href="#h62-e" y1="16436.01" y2="16444.35"/><linearGradient gradientTransform="matrix(1 0 0 -1 1.38 16454.78)" id="h62-g" x1="53.26" x2="57.62" xlink:href="#h62-d" y1="16439.59" y2="16435.96"/><linearGradient id="h62-h" x1="63.49" x2="68.84" xlink:href="#h62-a" y1="16450.53" y2="16450.53"/><filter id="h62-i" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><radialGradient cx=".5" cy=".25" id="h62-j" r="1"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><radialGradient cx=".5" cy=".25" id="h62-k" r="1.5" xlink:href="#h62-j"/><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h62-l" x1="77.44" x2="142.56" xlink:href="#h62-a" y1="139.45" y2="139.45"/><linearGradient gradientTransform="translate(220 264) rotate(180)" gradientUnits="userSpaceOnUse" id="h62-m" x1="97.63" x2="97.63" y1="137.15" y2="149.22"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="translate(220 264) rotate(180)" id="h62-n" x1="91.95" x2="91.95" xlink:href="#h62-e" y1="137.07" y2="148.94"/><linearGradient gradientUnits="userSpaceOnUse" id="h62-o" x1="91.57" x2="128.43" y1="134.53" y2="134.53"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><symbol id="h62-p" viewBox="0 0 77.53 84.96"><path d="M.14 81.94l3.63 3 1.58-.15L0 80.36Z" fill="url(#h62-a)"/><path d="M0 80.36l5.35 4.45 31.7-39.88L70.57 6.55 65.22 2.1 33.52 42Z" fill="url(#h62-b)"/><path d="M77.53 33.32C68.86 17.69 59.12 14.85 59.12 14.85S54.58 5.79 37.63.07c0 0 14.75-1.42 26.7 8.54S77.53 33.32 77.53 33.32Z" fill="url(#h62-c)"/><path d="M71.13 20.64l-9-9.46L51.26 4.08a65 65 0 0 0-13.63-4C54.58 5.79 59.12 14.85 59.12 14.85s9.74 2.84 18.41 18.47A65 65 0 0 0 71.13 20.64Z" fill="url(#h62-d)"/><path d="M51.26 4.08A33 33 0 0 1 71.13 20.64a43.13 43.13 0 0 0-3.37-3.16 35.25 35.25 0 0 0-3.12-2.31l-4.33 5.19-6.83-5.69 4.33-5.19A33.18 33.18 0 0 0 55 6.83 41 41 0 0 0 51.26 4.08Z" fill="url(#h62-e)"/><path d="M62.14 11.18l0 0a3.34 3.34 0 0 1 .37 4.69l-2.39 2.87-5.1-4.25 2.39-2.87A3.33 3.33 0 0 1 62.14 11.18Z" fill="url(#h62-f)"/><path d="M60.31 20.36l-.14-1.58-5.1-4.25-1.59.14Z" fill="url(#h62-g)"/><path d="M66.8 2l3.62 3 .15 1.58L65.22 2.1Z" fill="url(#h62-h)"/><path d="M59.27 19.49l-1.42 1.62-3.32-5.57Z"/></symbol></defs><g filter="url(#h62-i)"><use height="84.96" transform="matrix(-1 0 0 1 144.46 87.19)" width="77.53" xlink:href="#h62-p"/><use height="84.96" transform="translate(75.54 87.19)" width="77.53" xlink:href="#h62-p"/><path d="M110 113.48c12.85 0 18.43 8.52 18.43 21v5l-36.81.52-.05-5.52C91.57 122 97.15 113.48 110 113.48Z" fill="url(#h62-j)"/><polygon fill="url(#h62-k)" points="128.43 135.03 91.57 135.03 77.44 138.31 77.44 139.31 142.56 139.31 142.56 138.31 128.43 135.03"/><path d="M77.44 138.32v1c2.24 1.73 63 1.68 65.12 0v-1C140.65 139.67 79.2 139.57 77.44 138.32Z" fill="url(#h62-l)"/><path d="M127.59 115.06v11.87a30.68 30.68 0 0 0-10.45-12.07Z" fill="url(#h62-m)"/><path d="M127.59 115.06l.93.93v10l-.93.93" fill="url(#h62-n)"/><rect fill="url(#h62-o)" height="1" width="36.85" x="91.57" y="134.03"/></g>'
					)
				)
			);
	}

	function hardware_63() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Flower Pot',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><linearGradient id="h63-a" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h63-b" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h63-c" x1="0" x2="0" xlink:href="#h63-b" y1="1" y2="0"/><linearGradient id="h63-d" x1="0" x2=".25" y1="1" y2="-.1"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><radialGradient cx=".5" cy=".25" id="h63-w" r=".9"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><filter id="h63-aa" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient id="h63-ac" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="gray"/><stop offset="0.25" stop-color="#4b4b4b"/><stop offset="0.75" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><symbol id="h63-ai" viewBox="0 0 5.63 5.85"><path d="M5.63 0C4.8 5.56.8 3.43.2 5.85-.06 3.28 5 1.6 5.63 0Z" fill="url(#h63-b)"/><path d="M.2 5.85C.4 2.58 3.4 3.84 5.63 0 3.84 1.81-1 1.62.2 5.85" fill="url(#h63-d)"/></symbol><symbol id="h63-ar" viewBox="0 0 17.05 18.52"><path d="M14.2 4.06a5.51 5.51 0 0 0-4.46 3.3 9.4 9.4 0 0 0-1.22 3.39A9.2 9.2 0 0 0 7.31 7.36a5.54 5.54 0 0 0-4.47-3.3C1.07 4 .05 4.46 0 4.72c0 .44.75.3 1.9 1.17A11.18 11.18 0 0 1 5 10.08a43.44 43.44 0 0 1 1.48 5.63 4 4 0 0 0 1.41 2.38 2 2 0 0 0 1.35 0 4 4 0 0 0 1.4-2.38 45.12 45.12 0 0 1 1.48-5.63 11.29 11.29 0 0 1 3.06-4.19c1.15-.87 1.91-.73 1.91-1.17C17 4.46 16 4 14.2 4.06Z" fill="url(#h63-w)"/><path d="M10.18 13.75c.13-2 1.11-5.85.85-7.83C10.7 3.41 9.43 0 8.52 0S6.38 3.11 6 5.92c-.28 2.11.7 5.77.84 7.82.18 2.56.57 4.72 1.66 4.77S10 16.53 10.18 13.75Z" fill="url(#h63-w)"/></symbol><symbol id="h63-ah" viewBox="0 0 36.53 93.89"><path d="M6.86 43c.45-4.61 4-11.31 12.24-15.38l.41 1.44C13.93 30.75 9 36 7.64 42.87m-3 .41c.78-13.77 5-24.56 7.21-27.22l-1.07-.81c-3.36 5-6.68 18.15-7.07 28.07" fill="url(#h63-a)"/><use height="5.85" transform="translate(1.31 14.81)" width="5.63" xlink:href="#h63-ai"/><use height="5.85" transform="matrix(-0.59 -0.81 -0.81 0.59 19.51 27.06)" width="5.63" xlink:href="#h63-ai"/><use height="5.85" transform="translate(1.05 26.79) rotate(-3.6) scale(0.73)" width="5.63" xlink:href="#h63-ai"/><use height="5.85" transform="matrix(-0.61 -0.39 -0.39 0.61 11.88 32.56)" width="5.63" xlink:href="#h63-ai"/><use height="5.85" transform="matrix(0.8 0.23 -0.23 0.8 7.68 25.32)" width="5.63" xlink:href="#h63-ai"/><use height="5.85" transform="matrix(0.58 0.59 -0.59 0.58 12.71 34.36)" width="5.63" xlink:href="#h63-ai"/><use height="5.85" transform="matrix(-0.82 -0.14 -0.14 0.82 7.46 21.4)" width="5.63" xlink:href="#h63-ai"/><use height="5.85" transform="matrix(0.97 0.42 -0.42 0.97 10.83 17.08)" width="5.63" xlink:href="#h63-ai"/><use height="5.85" transform="matrix(0.57 0.89 -0.89 0.57 17.95 29.55)" width="5.63" xlink:href="#h63-ai"/><path d="M19.94 51.85A2.6 2.6 0 0 1 17.1 54.1c-3.79 0-4.5-10.6 6-10.6A10.2 10.2 0 0 1 33.13 53.74C33.13 67.17 16 66.51 16 73.41c0 3.83 4.34 3.88 4.8 1.21" fill="none" stroke="url(#h63-b)" stroke-width="1.6"/><path d="M21.43 52A4.1 4.1 0 0 1 17.1 55.6c-5.91 0-6.35-13.6 6-13.6 6.86 0 11.55 6 11.55 11.74 0 8.71-7.27 12.18-11.84 14.72-3.3 1.83-5.33 3.05-5.33 5 0 .93.37 1.51 1 1.56a.73.73 0 0 0 .83-.6" fill="none" stroke="url(#h63-c)" stroke-width="1.6"/><path d="M8.78 47.72H6.18s.23 4.62 6.45 10.11L18.4 58C8.45 52.29 8.78 47.72 8.78 47.72Z" fill="url(#h63-d)"/><path d="M6 83.31H3.75s0 5.83 4.32 9l6.31 0C4.6 90.17 6 83.31 6 83.31Z" fill="url(#h63-a)"/><path d="M12.61 58l-.41-.37c-1-.53-3.65-1.61-5.54.37 0 0 .38 18-4.74 25.35H3.75C13 74.71 12.61 58 12.61 58Z" fill="url(#h63-a)"/><path d="M5.16 93l2.91-.65c-4.32-3.17-4.32-9-4.32-9H1.92S2.15 89.05 5.16 93Z" fill="url(#h63-a)"/><path d="M2.66 47.72s1.06 6.79 4 10.24c1.89-2 4.53-.9 5.54-.37-6.21-5.5-6-9.87-6-9.87" fill="url(#h63-a)"/><path d="M6.18 47.72H2.66s1.06 6.79 4 10.24l6-.13C6.41 52.34 6.18 47.72 6.18 47.72Z" fill="url(#h63-d)"/><path d="M8.78 47.72a4.22 4.22 0 0 0-1.67-6.28H4.29c2.57 1.36 3.79 4 1.89 6.28" fill="url(#h63-d)"/><path d="M6.18 47.72c1.9-2.32.68-4.92-1.89-6.28H2.36a4.54 4.54 0 0 1 .3 6.28" fill="url(#h63-d)"/><path d="M2.36 41.44H1C.11 43.5.72 47.72.72 47.72H2.66A4.54 4.54 0 0 0 2.36 41.44Z" fill="url(#h63-d)"/><path d="M.82 83.31h1.1C7 76 6.66 58 6.66 58A11.2 11.2 0 0 0 .92 56.4 11.2 11.2 0 0 1 6.66 58c-2.94-3.45-4-10.24-4-10.24" fill="url(#h63-a)"/><path d="M.82 83.31h1.1C7 76 6.66 58 6.66 58A11.2 11.2 0 0 0 .92 56.4 11.2 11.2 0 0 1 6.66 58c-2.94-3.45-4-10.24-4-10.24" fill="url(#h63-a)"/><path d="M1.92 83.31H.82l.1 10.58L5.16 93C2.15 89.05 1.92 83.31 1.92 83.31Z" fill="url(#h63-a)"/><path d="M1.92 83.31H.82l.1 10.58L5.16 93C2.15 89.05 1.92 83.31 1.92 83.31Z" fill="url(#h63-a)"/><path d="M1.92 83.31H.82a38.3 38.3 0 0 0 .1 10.58L5.16 93C2.15 89.05 1.92 83.31 1.92 83.31Z" fill="url(#h63-d)"/><path d="M2.66 47.72H.72C.08 51 .92 56.4.92 56.4h0A13.26 13.26 0 0 1 6.66 58C3.72 54.51 2.66 47.72 2.66 47.72Z" fill="url(#h63-d)"/><path d="M12.63 57.83c-.62-.68-4-1.43-6 .13L1.92 83.31H6C16.08 70.51 12.63 57.83 12.63 57.83Z" fill="url(#h63-d)"/><path d="M18.4 58s-3.25-1.74-5.77-.13c0 0 0 16.59-8.88 25.48H6C19.8 74.71 18.4 58 18.4 58Z" fill="url(#h63-d)"/><path d="M6.66 58A13.26 13.26 0 0 0 .92 56.4h0c-2 12.65-.1 26.91-.1 26.91h1.1C7 76 6.66 58 6.66 58Z" fill="url(#h63-d)"/><path d="M5 93.08l3.84-.74c-4.31-3.17-5.08-9-5.08-9H1.92S2 89.18 5 93.08Z" fill="url(#h63-d)"/><use height="18.52" transform="translate(18.4 -3.26) rotate(45.78)" width="17.05" xlink:href="#h63-ar"/><use height="18.52" transform="translate(33.84 14.43) rotate(71.78)" width="17.05" xlink:href="#h63-ar"/></symbol></defs><g filter="url(#h63-aa)"><use height="93.89" transform="translate(109.08 90.6)" width="36.53" xlink:href="#h63-ah"/><use height="93.89" transform="matrix(-1 0 0 1 110.92 90.6)" width="36.53" xlink:href="#h63-ah"/><path d="M110.44 133.07c.33-10.33-.28-23.83.56-31.54h-2c.84 9.26.23 20.85.56 31.54" fill="url(#h63-a)"/><use height="18.52" transform="translate(101.47 83.96)" width="17.05" xlink:href="#h63-ar"/><path d="M101.19 137.53h17.69a.79.79 0 1 1 0 1.58H101.19a.79.79 0 1 1 0-1.58Z" fill="url(#h63-ac)"/><path d="M102.29 131.57h15.49a.8.8 0 0 1 0 1.6H102.29a.8.8 0 0 1 0-1.6Z" fill="url(#h63-ac)"/><path d="M96.05 182.91h28a1.11 1.11 0 0 1 0 2.21h-28a1.11 1.11 0 1 1 0-2.21Z" fill="url(#h63-ac)"/><path d="M103.09 172.44H117a.74.74 0 0 1 .74.74.73.73 0 0 1-.74.73H103.09a.73.73 0 0 1-.74-.73A.74.74 0 0 1 103.09 172.44Z" fill="url(#h63-ac)"/><path d="M104.45 173.87h11.16a.74.74 0 1 1 0 1.47H104.45a.74.74 0 0 1 0-1.47Z" fill="url(#h63-ac)"/></g>'
					)
				)
			);
	}
}
