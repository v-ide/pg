import vweb
import os
import net.http

const (
	port        = 80
	vexeroot    = @VEXEROOT
	block_size  = 4096
	inode_ratio = 16384
)

struct App {
	vweb.Context
}

['/'; get]
fn (mut app App) index() vweb.Result {
	app.add_header('Access-Control-Allow-Origin', '*')
	return $vweb.html()
}

['/run'; post]
fn (mut app App) run() vweb.Result {
	println('Got run request...')
	app.add_header('Access-Control-Allow-Origin', '*')
	code := app.form['code'] or { return app.text('No code was provided.') }
	
	dir := os.join_path(os.temp_dir(), 'playground-comp')
	os.mkdir(dir) or {}
	
	path := os.join_path(dir, 'code.v')
	out := os.join_path(dir, 'code.js')
	os.write_file(path, code) or {}
	println('building run request...')
	res := os.execute('$vexeroot/v -b js_browser -skip-unused ' + path + ' -o ' + out)
	
	println('reading output...')
	lines := os.read_lines(out) or {['Error: ' + res.str()]}
	os.rm(out) or {}
	
	mut str := ''
	for line in lines {
		str = str + '\n' + line.trim_space()
	}
	println('sending response.')

	
	fix_broken_v_js_backend := 'function require(a){} var process = 0;'
	
	return app.html("<script> $fix_broken_v_js_backend \n $str </script>")
	//return app.text(str)
}

['/format'; post]
fn (mut app App) format() vweb.Result {
	return app.text('todo')
}

fn (mut app App) init_once() {
	// os.execute('isolate --cleanup')
	app.handle_static('static', true)
	app.serve_static('/static/js/codejar.js', 'static/js/codejar.js')
}

fn main() {
	mut app := &App{}
	app.init_once()
	app.add_header('Access-Control-Allow-Origin', '*')
	app.set_cookie(http.Cookie{
        name: 'SameSite'
        value: 'Lax'
    })
	
	vweb.run(app, port)
}

pub fn (mut a App) before_request() {
	dump('TEST')
	a.add_header('Access-Control-Allow-Origin', '*')
	// a.req.header.add()
	
	headers_close     := http.new_custom_header_from_map({
		'Access-Control-Allow-Origin': '*'
	}) or { panic('should never fail') }
	// a.header << headers_close
	
	a.header = a.header.join(headers_close)
	a.header.add(.access_control_allow_origin, '*')
	
	dump(a.get_header('Access-Control-Allow-Origin'))
}