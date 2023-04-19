const fs = require('fs');
const { buffer } = require('stream/consumers');
const size = 128;

fs.readFile('TestFrame.bmp', (err, data) => {

	var memory = Buffer.alloc((128+16)*128);

	let point = data.readUInt8(10);
	let o = 0;
	for (let j = 0; j < size; j++) {
		for (let i = 0; i < size; i++) {
			let c = data.readUInt8(point);
			memory.write((c < 128) ? '0' : '1', o + i + j*128);
			if ((i+1) % 8 == 0) {
				o++;
				memory.write(' ', o + i + j*128);
			}
			point += 3;
		}
		memory.write('\n', o + 127 + j*128);
	}

	fs.writeFile('Memory.mem', memory, (err) => {
		console.log('file saved i guess')
	});
})