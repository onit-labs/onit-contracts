const colorMap = new Map([
	[0x000080, 'Navy Blue'],
	[0x0047ab, 'Cobalt'],
	[0x013f6a, 'Aqua Deep'],
	[0x0bda51, 'Malachite']
])
const fieldColors = Array.from(colorMap.keys())
const titles = Array.from(colorMap.values())

export { colorMap, fieldColors, titles }
