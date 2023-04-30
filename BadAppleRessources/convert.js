const fs = require('fs');
const size = 128;
var frame = 228; // start frame

createBuffer = function(num) {
	return Buffer.from(num.toString(2).padStart(8, "0") + ' ');
}

// delete file and call other stuff
fs.truncate('Memory.mem', 0, () => run());

function run() {
	var stream = fs.createWriteStream('Memory.mem', {flags: 'a'});

	while (writeFrame(stream, frame)) {
		console.log('frame ' + frame + ' written');
		frame += 3;
		if (frame > 315) break;
	}

	console.log('converted everything up to frame ' + (frame - 3));
	stream.end();
}

function writeFrame(stream, frame) {
	file = 'full/frame_' + frame.toString().padStart(4, '0') + '.bmp';

	if (!fs.existsSync(file)) return false;
	let data = fs.readFileSync(file);

	let chunks = [];

	let point = data.readUInt8(10) + 128*3*16;

	// write frame info
	let last = data.readUInt8(point) >= 128;
	let count = 0;
	chunks.push(createBuffer(last ? 1 : 0));

	for (let j = 16; j < size-16; j++) {
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
	return true;
}