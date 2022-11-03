import fs = require('fs')

export function printSVGToSnapshots(type: string, title: string, svgString: string) {
	fs.writeFileSync(`./${title}.svg`, svgString)
}
