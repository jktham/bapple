const fs = require('fs');
const size = 128;

fs.readFile('TestFrame.bmp', (err, data) => {

	var buffer = [...data];

	// debug ascii art
	let img = "";
	let point = buffer[10]
	for (let i = 0; i < size; i++) {
		let line = "";
		for (let i = 0; i < size; i++) {
			let b = buffer[point], g = buffer[point+1], r = buffer[point+2];
			if (!(r === g && g === b)) console.err("colors are not greyscale");
			line += (r*g*b < 8290688) ? "  " : "00";
			point += 3;
		}
		img = line + "\n" + img;
	}

	console.log(img);
})