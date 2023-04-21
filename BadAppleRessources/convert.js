const fs = require('fs');
const size = 128;

fs.truncate('Memory.mem', 0, () => {});

var stream = fs.createWriteStream('Memory.mem', {flags: 'a'});

createBuffer = function(num) {
	return Buffer.from(num.toString(2).padStart(8, "0") + ' ');
}

fs.readFile('TestFrame.bmp', (err, data) => {

	let chunks = [];

	let point = data.readUInt8(10);

	// write frame info
	let last = data.readUInt8(point) >= 128;
	let count = 0;
	chunks.push(createBuffer(last ? 255 : 254)); // max number of length is 253 (255 and 254 are codes for frame data)

	for (let j = 0; j < size; j++) {
		for (let i = 0; i < size; i++) {
			let c = data.readUInt8(point)
			let current = c >= 128;
			if (current == last) {
				count++;
				if (count >= 255) {
					chunks.push(createBuffer(255));
					count = 0;
				}
			} else {
				chunks.push(createBuffer(count));
				count = 1;
			}
			last = current;
			point += 3;
		}
	}

	chunks.push(createBuffer(count));
	chunks.push(Buffer.from('\n'));

	stream.write(Buffer.concat(chunks));

	stream.end();
})