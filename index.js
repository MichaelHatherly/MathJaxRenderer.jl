process.stdin.setEncoding('utf8');
let input = '';
process.stdin.on('data', chunk => {
    input += chunk;
});
process.stdin.on('end', () => {
    let args = JSON.parse(input);
    require('mathjax').init({
        loader: {load: [`input/tex`, 'output/svg']},
    }).then((MathJax) => {
        let svg = MathJax.tex2svg(args.src, args.config);
        process.stdout.write(MathJax.startup.adaptor.outerHTML(svg));
    }).catch((err) => console.log(err.message));
});
