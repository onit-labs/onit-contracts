// SPDX-License-Identifier: The Unlicense
/// @author Modified from Area-Technology (https://github.com/Area-Technology/shields-contracts/tree/main/contracts/SVGs)

pragma solidity ^0.8.13;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs13 is IHardwareSVGs, ICategories {
	function hardware_48() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Shipwheel',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h48-a" x1=".17" x2="5.37" y1="30.7" y2="30.7"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 16380.4)" id="h48-c" x1=".17" x2="5.37" xlink:href="#h48-a" y1="16368.99" y2="16368.99"/><linearGradient gradientUnits="userSpaceOnUse" id="h48-d" x1=".05" x2="4.86" y1="27.47" y2="27.47"><stop offset="0" stop-color="gray"/><stop offset=".24" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h48-h" x1="110" x2="110" xlink:href="#h48-a" y1="166.46" y2="97.54"/><linearGradient id="h48-i" x1="83.54" x2="136.46" xlink:href="#h48-a" y1="132" y2="132"/><linearGradient gradientUnits="userSpaceOnUse" id="h48-b" x1="77.04" x2="142.96" y1="132" y2="132"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h48-j" x1="100.49" x2="119.51" xlink:href="#h48-b"/><linearGradient id="h48-k" x1="110" x2="110" xlink:href="#h48-a" y1="141.68" y2="122.32"/><linearGradient id="h48-l" x1="105.27" x2="114.73" xlink:href="#h48-a" y1="132" y2="132"/><radialGradient cx=".5" cy=".1" id="h48-e" r="1.5"><stop offset="0" stop-color="#fff"/><stop offset=".32" stop-color="#4b4b4b"/><stop offset=".67" stop-color="#fff"/><stop offset=".82" stop-color="#4b4b4b"/><stop offset=".98" stop-color="#fff"/></radialGradient><symbol id="h48-g" viewBox="0 0 5.54 43.2"><path d="m2.77 27.47-2.6-2.59 2.6-.82 2.6.82Zm0 6.44-2.6 2.6 2.6.84 2.6-.84Z" fill="url(#h48-a)"/><path d="M3.93 10.3H1.61L.17 11.74l2.6.78 2.6-.78-1.44-1.44z" fill="url(#h48-c)"/><path d="M4.37 25.88c1.55 1.43 1.55 8.2 0 9.63h-3.2c-1.56-1.43-1.56-8.2 0-9.63m4.2 17.32v-6.67H.17v6.67ZM.17 24.88V11.74h5.2v13.14Z" fill="url(#h48-d)"/><path d="M2.77 21.93a5.64 5.64 0 0 0-2.6.34v1.12s.61-.6 2.6-.6 2.6.6 2.6.6v-1.12a5.64 5.64 0 0 0-2.6-.34Z"/><path d="M4.37 10.74A2.78 2.78 0 0 0 4.34 8l-.09-.12a2.17 2.17 0 0 1 0-2.37l.09-.12a4 4 0 0 0 0-4.49 1.83 1.83 0 0 0-3.15 0 4 4 0 0 0 0 4.36l.09.12a2.17 2.17 0 0 1 0 2.37L1.19 8a2.81 2.81 0 0 0 0 2.79Z" fill="url(#h48-e)"/></symbol><filter id="h48-f"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h48-f)"><use height="43.2" transform="translate(107.23 84.22)" width="5.53" xlink:href="#h48-g"/><use height="43.2" transform="matrix(.5 -.87 .87 .5 67.24 110.51)" width="5.53" xlink:href="#h48-g"/><use height="43.2" transform="rotate(-120 80.6965003 58.92985383)" width="5.53" xlink:href="#h48-g"/><use height="43.2" transform="rotate(180 56.385 89.89)" width="5.53" xlink:href="#h48-g"/><use height="43.2" transform="matrix(-.5 .87 -.87 -.5 152.76 153.49)" width="5.53" xlink:href="#h48-g"/><use height="43.2" transform="matrix(.5 .87 -.87 .5 149.99 105.72)" width="5.53" xlink:href="#h48-g"/><path d="M107.4 165.59V167a16.2 16.2 0 0 0 5.2 0v-1.4a14.2 14.2 0 0 1-5.2-.01Z"/><path d="M110 165.46A33.46 33.46 0 1 1 143.46 132 33.5 33.5 0 0 1 110 165.46Z" fill="none" stroke="url(#h48-h)" stroke-miterlimit="10" stroke-width="2"/><path d="M110 157.46A25.46 25.46 0 1 1 135.46 132 25.49 25.49 0 0 1 110 157.46Z" fill="none" stroke="url(#h48-i)" stroke-miterlimit="10" stroke-width="2"/><circle cx="110" cy="132" fill="none" r="29.46" stroke="url(#h48-b)" stroke-miterlimit="10" stroke-width="7"/><circle cx="110" cy="132" fill="none" r="6.96" stroke="url(#h48-j)" stroke-miterlimit="10" stroke-width="5.1"/><path d="M110 141.18a9.18 9.18 0 1 1 9.18-9.18 9.19 9.19 0 0 1-9.18 9.18Z" fill="none" stroke="url(#h48-k)" stroke-miterlimit="10"/><path d="M110 136.42a4.42 4.42 0 1 1 4.42-4.42 4.42 4.42 0 0 1-4.42 4.42Z" fill="none" stroke="url(#h48-l)" stroke-miterlimit="10" stroke-width=".63"/></g>'
					)
				)
			);
	}

	function hardware_49() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Pipe Organ',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><linearGradient id="h49-a" x1="0" x2="0" y1="0" y2=".6"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h49-c" x1="0" x2="0" xlink:href="#h49-a" y1="0" y2="8"/><linearGradient id="h49-b" x2="1" y1="0" y2="0"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h49-d" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".1" stop-color="gray"/><stop offset=".4" stop-color="#fff"/><stop offset=".6" stop-color="#fff"/><stop offset=".8" stop-color="gray"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h49-f" x1="0" x2="0" y1="1" y2="0"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h49-g" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><symbol id="h49-h" viewBox="0 0 3.2 2.9"><path d="M3.2 2.4s0 .5-1.6.5S0 2.4 0 2.4v-2h3.2Z" fill="url(#h49-b)"/><path d="M3.2 0H0v1.4h3.2Z"/></symbol><symbol id="h49-e" viewBox="0 0 8 21.1"><path d="M0 19.1V2a5 5 0 0 1 8 0v17a5 5 0 0 1-8 0Z" fill="url(#h49-a)"/><path d="M8 12.2H0v1h8Z" fill="url(#h49-c)"/><path d="M8 13.2H0v2h8Z"/></symbol><symbol id="h49-i" viewBox="0 0 35 76.5"><path d="M20 62V13s0-3-5-3-5 3-5 3v49l3 14s0 .5 2 .5 2-.5 2-.5l3-14Z" fill="url(#h49-d)"/><path d="M10 62V3s0-3-5-3-5 3-5 3v59l3 14s0 .5 2 .5 2-.5 2-.5l3-14Z" fill="url(#h49-d)"/><use height="21.1" transform="translate(1 37)" width="8" xlink:href="#h49-e"/><use height="21.1" transform="translate(11 32)" width="8" xlink:href="#h49-e"/><path d="M27.5 18.5C25 18.5 25 20 25 20v42l2 10.5h1L30 62V20s0-1.5-2.5-1.5Z" fill="url(#h49-d)"/><path d="M22.5 21.5C20 21.5 20 23 20 23v39l2 10.5h1L25 62V23s0-1.5-2.5-1.5Z" fill="url(#h49-d)"/><path d="M32.5 15.5C30 15.5 30 17 30 17v45l2 10.5h1L35 62V17s0-1.5-2.5-1.5Z" fill="url(#h49-d)"/><use height="21.1" transform="matrix(.5 0 0 .5 20.5 35.7)" width="8" xlink:href="#h49-e"/><use height="21.1" transform="matrix(.5 0 0 .5 25.5 32.7)" width="8" xlink:href="#h49-e"/><use height="21.1" transform="matrix(.5 0 0 .5 30.5 29.7)" width="8" xlink:href="#h49-e"/></symbol></defs><path d="M86.4 171.6 85 173v1h50v-1l-1.4-1.4H86.4z"/><path d="m147.7 161.7 2.3-12.1V107l-10 6h-5l-20-20h-10l-20 20h-5l-10-5.9v42.5l2.3 12L69 165v1h14l.2.3L86 170h48l3-4h14v-1Zm-73.4 2L76 155l1.7 8.6Zm5 0L81 155l1.7 8.6Zm5 0L86 155l2.8 12.6Zm9 4L96 155l2.8 12.6Zm10 0L106 155h8l2.8 12.6Zm17 0L124 155l2.8 12.6Zm11 0L134 155l1.7 8.6Zm6-4 1.7-8.7 1.7 8.6Zm5 0 1.7-8.7 1.7 8.6Z"/><path d="m84.9 161.6 3 4-1.4 2-4.2-4.2Zm50.2 0-3 4 1.3 1.8 4-4.4Z" fill="url(#h49-f)"/><path d="m135 171-25 .7-25-.7 1.4-1.4h47.2Zm-66-8 13.7.8 2.2-2.2H70.4Zm63.1 2.6 1.8 1.8H86.1l1.8-1.8ZM151 163l-13.8.7-2-2h14.4Z" fill="url(#h49-g)"/><use height="2.9" transform="translate(128.4 167.6)" width="3.2" xlink:href="#h49-h"/><use height="2.9" transform="translate(118.4 167.6)" width="3.2" xlink:href="#h49-h"/><use height="2.9" transform="translate(108.4 167.6)" width="3.2" xlink:href="#h49-h"/><use height="2.9" transform="translate(98.4 167.6)" width="3.2" xlink:href="#h49-h"/><use height="2.9" transform="translate(88.4 167.6)" width="3.2" xlink:href="#h49-h"/><path d="M135 172H85v-1h50Zm16-9v1h-14l-3 4H86l-3-4H69v-1h14.5l3 4h47l3-4Z" fill="url(#h49-d)"/><path d="M115 152V83s0-3-5-3-5 3-5 3v69l3 14s0 .5 2 .5 2-.5 2-.5Z" fill="url(#h49-d)"/><use height="21.1" transform="translate(106 132)" width="8" xlink:href="#h49-e"/><use height="76.5" transform="translate(115 90)" width="35" xlink:href="#h49-i"/><use height="76.5" transform="matrix(-1 0 0 1 105 90)" width="35" xlink:href="#h49-i"/>'
					)
				)
			);
	}

	function hardware_50() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Knight',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><filter id="h50-a" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientUnits="userSpaceOnUse" id="h50-b" x1="109.12" x2="109.12" y1="153.17" y2="93.59"><stop offset="0" stop-color="#818181"/><stop offset="0.2" stop-color="#4c4c4c"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="#818181"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h50-c" x1="107.01" x2="91.81" y1="114.7" y2="127.58"><stop offset="0" stop-color="#818181"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h50-d" x1="107.6" x2="107.6" xlink:href="#h50-c" y1="148.61" y2="112.47"/><linearGradient id="h50-e" x1="86.77" x2="128.35" xlink:href="#h50-c" y1="126.12" y2="126.12"/><linearGradient id="h50-f" x1="109.6" x2="102.32" xlink:href="#h50-c" y1="101.43" y2="93.46"/><linearGradient id="h50-g" x1="102.85" x2="104.58" xlink:href="#h50-c" y1="105.01" y2="108.64"/><linearGradient gradientUnits="userSpaceOnUse" id="h50-h" x1="85" x2="135.01" y1="161" y2="161"><stop offset="0" stop-color="#818181"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="#818181"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h50-i" x1="83.27" x2="136.75" y1="163" y2="163"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="#818181"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h50-j" x1="85" x2="135.01" xlink:href="#h50-i" y1="159" y2="159"/><linearGradient gradientUnits="userSpaceOnUse" id="h50-k" x1="83.74" x2="130.21" y1="166.5" y2="166.5"><stop offset="0" stop-color="#818181"/><stop offset="0.24" stop-color="#4c4c4c"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4c4c4c"/></linearGradient><linearGradient id="h50-l" x1="83.27" x2="136.75" xlink:href="#h50-h" y1="170" y2="170"/><linearGradient gradientTransform="matrix(-1 0 0 1 220 0)" id="h50-m" x1="110" x2="110" xlink:href="#h50-c" y1="154.25" y2="158"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 308)" id="h50-n" x1="90" x2="130.01" xlink:href="#h50-h" y1="156.75" y2="156.75"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 308)" id="h50-o" x1="90" x2="130.01" xlink:href="#h50-i" y1="154.75" y2="154.75"/><linearGradient gradientTransform="translate(0 -1.5)" id="h50-p" x1="90" x2="130.01" xlink:href="#h50-i" y1="150.75" y2="150.75"/></defs><g filter="url(#h50-a)"><path d="M92.94 149.25c-1.4-14.73 17.79-21 17.06-32.92-4.71 7-11.57 2.47-17.62 9.48A12.84 12.84 0 0 1 85 120.87s14-14.07 18.77-22.7c-2-2.79-1.67-8.12-1.67-8.12 10 11 31.15 7.32 31.15 29.94 0 15.3-7.56 17.24-6.22 29.26" fill="url(#h50-b)"/><path d="M110 116.33a6.7 6.7 0 0 0 0-4.1L91.54 123.09l.84 2.72C98.43 118.8 105.29 123.34 110 116.33Z" fill="url(#h50-c)"/><path d="M120.46 150.25c-2.8-11.86 7.64-19.18 7.64-31.1C128.1 104.69 117.33 102 110 102c-5.8 0-11.57 8.59-22.9 18.37a8 8 0 0 0 4.43 2.72c7-5.65 16.22-2.48 18.46-10.86 14.43 6.68-8.23 20.94-4.6 38Z" fill="url(#h50-d)" stroke="url(#h50-e)" stroke-width="0.5"/><path d="M102.1 90.05c1 5.66 9.68 10.75 9.68 10.75-7.17-.65-8-2.63-8-2.63S100.79 94 102.1 90.05Z" fill="url(#h50-f)"/><path d="M100.38 108.43c.45-5.43 5.91-4.8 5.91-4.8C106.24 108.89 104.23 109.44 100.38 108.43Z" fill="url(#h50-g)"/><rect fill="url(#h50-h)" height="2" width="50.01" x="85" y="160"/><polygon fill="url(#h50-i)" points="135.01 162 85 162 83.27 164 136.75 164 135.01 162"/><polygon fill="url(#h50-j)" points="133.37 158 86.64 158 85 160 135.01 160 133.37 158"/><rect fill="url(#h50-k)" height="5" width="53.48" x="83.27" y="164"/><polygon fill="url(#h50-l)" points="83.27 169 85 171 135.01 171 136.75 169 83.27 169"/><path d="M126.51 158a2 2 0 0 1 0-3.75h-33a2 2 0 0 1 0 3.75Z" fill="url(#h50-m)"/><rect fill="url(#h50-n)" height="2" width="40.01" x="90" y="150.25"/><polygon fill="url(#h50-o)" points="128.37 154.25 91.64 154.25 90 152.25 130.01 152.25 128.37 154.25"/><polygon fill="url(#h50-p)" points="128.37 148.25 91.64 148.25 90 150.25 130.01 150.25 128.37 148.25"/></g>'
					)
				)
			);
	}

	function hardware_51() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Garb',
				HardwareCategories.BASIC,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16404.52)" gradientUnits="userSpaceOnUse" id="h51-a" x1="3.59" x2="3.59" y1="16384.78" y2="16401.43"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h51-b" x1="3.62" x2="3.62" xlink:href="#h51-a" y1="16401.39" y2="16388.74"/><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h51-c" x1="11.48" x2="11.48" xlink:href="#h51-a" y1="62.22" y2="0.85"/><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h51-d" x1="12.2" x2="12.2" xlink:href="#h51-a" y1="0" y2="62.13"/><filter id="h51-e" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h51-f" x1="109.5" x2="109.5" xlink:href="#h51-a" y1="175.98" y2="113.32"/><linearGradient gradientTransform="matrix(1 0 0 1 0 0)" id="h51-g" x1="110.5" x2="110.5" xlink:href="#h51-a" y1="113.32" y2="175.98"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h51-h" x1="96.44" x2="123.56" y1="122.94" y2="122.94"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h51-i" x1="96.46" x2="121.49" y1="116.25" y2="116.25"><stop offset="0" stop-color="#4b4b4b"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h51-j" x1="95.28" x2="124.72" y1="119.45" y2="119.45"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><symbol id="h51-k" viewBox="0 0 25.63 62.22"><path d="M19.45 1c4 14.72 4.41 46.92-1.18 61.06M15 2.81c7.83 14 7.62 44.87-2.58 57.71M11.24 5.72C22.55 19.34 20.49 46.07 7.7 58.27M8.33 9.51c13.83 11.64 9.1 35.67-4.18 46M6.5 13.93c6 2.35 8 9.43 8.08 15.31.35 9.3-6 17.39-13.13 22.72M5.87 18.67c6.68.73 7.68 9.43 6.33 14.72-2 6-6.79 10.42-11.93 13.77" fill="none" stroke="url(#h51-c)" stroke-miterlimit="10"/><path d="M20.37.12c3.88 15.82 4.52 47.68-1.06 61.82M15.6 2.07c7.86 14.35 7.93 46-2.43 59M11.88 5c11.85 13.68 9.59 41.52-3.52 54M8.7 8.68c14.49 12 9.73 36.91-4 47.63M6.76 13.15c6.93 2.79 8.73 10.21 8.82 16.09C15.93 38.54 9.11 47.45 2 52.78m3.75-35c7.7.94 8.8 10.37 7.45 15.66-2 6-7.29 11.31-12.43 14.66" fill="none" stroke="url(#h51-d)" stroke-miterlimit="10"/><path d="M25.63 35.76h-15l-.36.87 1.12-.22.95 1.1 1.51-.63.89 1L16 37.18l1 1.14 1.37-.86 1 .92 1-.74 1.15 1 1.22-.79.93 1 1-.76"/></symbol><symbol id="h51-m" viewBox="0 0 7.19 20.52"><path d="M0 1.78.75 17.39s.17 3.13 2.85 3.13 2.85-3.13 2.85-3.13L7.19 1.78S6.49.94 3.6.94 0 1.78 0 1.78Z" fill="url(#h51-a)"/><path d="M1.17.25c.3-.07.6-.13.9-.17l.17 16.6H1.75Zm4-.17L5 16.68h.49L6.07.25A7.4 7.4 0 0 0 5.13.08ZM4.1 0H3.18L3.4 16.68h.48Z" fill="url(#h51-b)"/></symbol><symbol id="h51-n" viewBox="0 0 36.12 41.51"><use height="20.52" transform="translate(25.31 1.33) rotate(-15)" width="7.19" xlink:href="#h51-m"/><use height="20.52" transform="matrix(0.87 -0.5 0.5 0.87 16.31 6.08)" width="7.19" xlink:href="#h51-m"/><use height="20.52" transform="translate(8.83 12.99) rotate(-45)" width="7.19" xlink:href="#h51-m"/><use height="20.52" transform="matrix(0.5 -0.87 0.87 0.5 3.41 21.61)" width="7.19" xlink:href="#h51-m"/><use height="20.52" transform="translate(0.39 31.34) rotate(-75)" width="7.19" xlink:href="#h51-m"/><use height="20.52" transform="translate(0 41.51) rotate(-90)" width="7.19" xlink:href="#h51-m"/></symbol></defs><g filter="url(#h51-e)"><path d="M109.5 176V113.32" fill="none" stroke="url(#h51-f)" stroke-miterlimit="10"/><path d="M110.5 176V113.32" fill="none" stroke="url(#h51-g)" stroke-miterlimit="10"/><use height="62.22" transform="translate(85.31 113.44)" width="25.63" xlink:href="#h51-k"/><use height="62.22" transform="matrix(-1 0 0 1 134.69 113.44)" width="25.63" xlink:href="#h51-k"/><path d="M123.56 140.52l-.62-.92H97.06l-.62.92 14.5 2Z" fill="url(#h51-h)"/><path d="M95.28 148.58l.35.94h28.74l.35-.94L110.94 146Z" fill="url(#h51-i)"/><use height="20.52" transform="translate(106.4 93.27)" width="7.19" xlink:href="#h51-m"/><use height="41.51" transform="translate(71.15 94.2)" width="36.12" xlink:href="#h51-n"/><use height="41.51" transform="matrix(-1 0 0 1 148.85 94.2)" width="36.12" xlink:href="#h51-n"/><path d="M123.56 140.52H96.44s.13 5.58-1.16 8.06h29.44C123.43 146.1 123.56 140.52 123.56 140.52Z" fill="url(#h51-j)"/></g>'
					)
				)
			);
	}
}
