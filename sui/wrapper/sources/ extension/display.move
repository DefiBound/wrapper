/// Module: display
module wrapper::display {
    use std::string::{Self,String};
    use std::vector;
    use sui::display::{Self, Display};

    use wrapper::wrapper::{Self, Wrapper};

    // === SVG ===
    const SVG_BG_PREFIX: vector<u8> = b"%3Cpattern id='bg' patternUnits='userSpaceOnUse' x='0' y='0' width='120' height='120'%3E%3Cimage href='";
    // const SVG_BG_VALUE: vector<u8> = b"data:image/svg+xml;base64,Cjxzdmcgd2lkdGg9IjU1NiIgaGVpZ2h0PSI1NDYiIHZpZXdCb3g9IjAgMCA1NTYgNTQ2IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDwhLS0gSGV4YWdvbiBzaGFwZSAtLT4KICA8cG9seWdvbiBwb2ludHM9IjM4Myw2NiAxMzEsNzkgMjYsMjgyIDE0Niw0OTAgNDAwLDQ3NSA1MDMsMjcxIiBmaWxsPSIjNjY2IiAvPgogIAogIDwhLS0gU2ltcGxpZmllZCBDb250b3VyIHBhdGhzIC0tPgogIDxwYXRoIGQ9Ik0gMTg2LDI5OCBMIDE2MSwyOTcgTCAxNjYsMzEwIEwgMTgwLDI5NyBMIDE4OSwzMDIgTCAyMDEsMzQ4IEwgMTk5LDM2NCBMIDE4OSwzNjggTCAxMzIsMzYyIEwgMTg5LDM2OCBMIDE5OSwzNjQgTCAyMDEsMzQ4IFogTSAzODQsNjcgTCAxMjksODMgTCAyNiwyODYgTCAxNDMsNDg4IEwgNDAyLDQ3MSBMIDUwMywyNzEgTCAzNjgsNDk0IEwgMTQ1LDQ4OSBMIDI2LDI4NiBMIDE1Nyw2MiBMIDM4Miw2NiBMIDUwMiwyNjkgWiAiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2NjYyIgc3Ryb2tlLXdpZHRoPSIyIiAvPgo8L3N2Zz4K";
    const SVG_BG_END: vector<u8> = b"' width='120' height='120' /%3E%3C/pattern%3E";
    public fun create_svg_backgroun_image(base_64_bg: vector<u8>): vector<u8> {
        let mut image = vector::empty<u8>();
        vector::append(&mut image, SVG_BG_PREFIX);
        vector::append(&mut image, base_64_bg);
        vector::append(&mut image, SVG_BG_END);
        image
    }

    const SVG_TEXT_SPAN_PREFIX: vector<u8> = b"%3Ctspan font-size='";
    // const SVG_TEXT_SPAN_FONT_SIZE_VALUE: vector<u8> = b"2"; // font size
    const SVG_TEXT_SPAN_Y_POSITION_PREFIX: vector<u8> = b"' y='";
    // const SVG_TEXT_SPAN_Y_POSITION_VALUE: vector<u8> = b"15"; // y position
    const SVG_TEXT_SPAN_Y_POSITION_END: vector<u8> = b"%25' x='50%25' %3E";
    // const SVG_TEXT_SPAN_CONTEXT: vector<u8> = b"标题"; // title
    const SVG_TEXT_SPAN_END: vector<u8> = b"%3C/tspan%3E";
    public fun create_svg_text_span(
        text_context: vector<u8>,
        font_size: vector<u8>,
        y_position: vector<u8>
    ): vector<u8> {
        let mut span = vector::empty<u8>();
        vector::append(&mut span, SVG_TEXT_SPAN_PREFIX);

        vector::append(&mut span, font_size); //font size
        vector::append(
            &mut span,
            SVG_TEXT_SPAN_Y_POSITION_PREFIX
        );
        vector::append(&mut span, y_position); // y posiztion
        vector::append(
            &mut span,
            SVG_TEXT_SPAN_Y_POSITION_END
        );
        vector::append(&mut span, text_context); // text context
        vector::append(&mut span, SVG_TEXT_SPAN_END);
        span
    }

    public fun auto_create_svg_text_span(
        text_context: vector<u8>,
        y_position: u64,
        width: u64
    ): (vector<u8>, u64) {
        let mut span = vector::empty<u8>();
        let (font_size,_) = calculate_font_size(text_context.length(),120,width);
        let font_size_bytes = u64_to_bytes(font_size);

        let mut current_y_position = y_position;
        let line_height = font_size + 2;
        let mut lines = split_into_lines(text_context, font_size, 120);

        while(lines.length()>0) {
            vector::append(&mut span, SVG_TEXT_SPAN_PREFIX);
            vector::append(&mut span, font_size_bytes);
            vector::append(&mut span, SVG_TEXT_SPAN_Y_POSITION_PREFIX);
            vector::append(&mut span, u64_to_bytes(current_y_position));
            vector::append(&mut span, SVG_TEXT_SPAN_Y_POSITION_END);
            vector::append(&mut span, lines.remove(0));
            vector::append(&mut span, SVG_TEXT_SPAN_END);

            current_y_position = current_y_position + line_height;
        };

        (span, current_y_position)
    }

    const SVG_TEXT_MASK_PREFIX: vector<u8> = b"%3Cmask id='text'%3E%3Ctext fill='%23FFFFFF' font-size='12' text-anchor='middle'%3E";
    const SVG_TEXT_KIND: vector<u8> = b"%3Ctspan x='50%25' y='98%25' font-size='1'%3E{kind}%3C/tspan%3E";
    const SVG_TEXT_MASK_END: vector<u8> = b"%3C/text%3E%3C/mask%3E";
    fun create_svg_mask_text(mut spans: vector<vector<u8>>): vector<u8> {
        let mut mask = vector::empty<u8>();
        vector::append(&mut mask, SVG_TEXT_MASK_PREFIX);
        vector::append(&mut mask, SVG_TEXT_KIND);
        while (spans.length() > 0) {
            vector::append(&mut mask, spans.swap_remove(0));
        };
        spans.destroy_empty();
        vector::append(&mut mask, SVG_TEXT_MASK_END);
        mask
    }

    const SVG_USE_TEXT_MASK_PREFIX: vector<u8> = b"%3Crect width='120' height='120' fill='rgba(";
    const SVG_COMMA: vector<u8> = b",";
    const SVG_USE_TEXT_MASK_END: vector<u8> = b",1)' mask='url(%23text)' /%3E";
   fun set_svg_text_color(
        r: vector<u8>,
        g: vector<u8>,
        b: vector<u8>
    ): vector<u8> {
        let mut color = vector::empty<u8>();
        vector::append(
            &mut color,
            SVG_USE_TEXT_MASK_PREFIX
        );
        vector::append(&mut color, r); // r
        vector::append(&mut color, SVG_COMMA);
        vector::append(&mut color, g); // g
        vector::append(&mut color, SVG_COMMA);
        vector::append(&mut color, b); // b
        vector::append(&mut color, SVG_USE_TEXT_MASK_END);
        color
    }

    const SVG_PREFIX: vector<u8> = b"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000' viewBox='0 0 120 120'%3E %3Cdefs%3E";
    const SVG_WRAPPER_BG: vector<u8> = b"%3Cstyle%3E .st0 %7B fill: %23236D37; %7D .st1 %7B fill: %23C9CF79; %7D .st2 %7B fill: %237C9431; %7D .st3 %7B fill: %23FFFFFF; %7D %3C/style%3E%3Csymbol id='wrapper' viewBox='0 0 120 120'%3E%3Cpath class='st0' d='M83.49,110.3l-49.69-0.57c-2.14-0.02-4.09-1.21-5.1-3.09L5.2,62.84c-0.98-1.83-0.92-4.04,0.15-5.81L31.68,13.6 c1.08-1.77,3.01-2.85,5.08-2.82l49.69,0.57c2.14,0.02,4.09,1.21,5.1,3.09l23.49,43.8c0.98,1.83,0.92,4.04-0.15,5.81l-26.33,43.42 C87.49,109.25,85.56,110.32,83.49,110.3z' /%3E%3Cpath class='st1' d='M46.66,58.52c6.94,0.05,13.4-3.55,17-9.49L82.35,18.2c0.56-0.93-0.1-2.12-1.18-2.13l-37.22-0.46 c-4.79-0.06-9.25,2.42-11.73,6.51L11.59,56.13c-0.56,0.93,0.1,2.12,1.19,2.13L46.66,58.52z' /%3E%3Cpath class='st2' d='M28.64,94.19c2.99,6.11,8.98,10.01,15.77,10.26l34.86,0.62c1.06,0.04,1.82-1.12,1.36-2.08L64.46,71.21 c-2.04-4.23-6.17-6.93-10.85-7.1l-39.58-1.04c-1.06-0.04-1.82,1.13-1.35,2.08L28.64,94.19z' /%3E%3Cpath class='st3' d='M44.02,30.22c-10.62,6.14-16.61,17-16.17,28.16l7.35,0.06c-0.11-8.58,4.41-17.06,12.54-21.76 c4.8-2.77,10.12-3.8,15.18-3.28c1.52,0.16,2.97-0.66,3.57-2.06l0.08-0.18c0.93-2.14-0.44-4.58-2.76-4.89 C57.2,25.39,50.25,26.61,44.02,30.22z' /%3E%3Cpath class='st1' d='M44.47,76.93c0.33,2-1.27,3.68-3.26,3.43l-7.92-0.99l-3.83-0.38c-1.84-0.18-2.68-2.48-1.35-3.68l6.2-5.62 l4.92-5.03c0.91-0.93,2.54-0.41,2.85,0.91l1.73,7.37L44.47,76.93z' /%3E%3Cpath class='st1' d='M28.5,63.45c0.64,2.93,1.75,5.84,3.35,8.63l3.17-3.02L37,67.13c-0.48-1.14-0.85-2.31-1.14-3.49L28.5,63.45z' /%3E%3Cpath class='st1' d='M68.9,79.73c-4.05,1.7-8.33,2.27-12.45,1.82c-1.53-0.17-3,0.65-3.61,2.06l-0.1,0.23 c-0.91,2.1,0.43,4.5,2.7,4.82c5.59,0.78,11.43,0.08,16.88-2.3L68.9,79.73z' /%3E%3Cpath class='st2' d='M74.26,37.09c-0.35-1.99,1.24-3.69,3.24-3.45l8.04,0.65l4.24,0.38c1.84,0.17,2.7,2.46,1.38,3.67l-6.69,5.91 l-5.42,5.65c-0.9,0.94-2.54,0.43-2.86-0.89l-1.25-7.94L74.26,37.09z' /%3E%3Cpath class='st2' d='M84.73,43.84l-2.61,2.75c5.04,10.68,1.33,23.65-8.76,30.48l3.52,6.6c13.95-9.01,18.54-27.44,10.25-42.01 L84.73,43.84z' /%3E%3C/symbol%3E";
    // create_svg_backgroun_image
    // create_svg_mask_text
    const SVG_MID: vector<u8> = b"%3C/defs%3E";
    // use wrapper
    const SVG_USE: vector<u8> = b"%3Crect width='120' height='120' fill='url(%23bg)' /%3E %3Crect width='120' height='120' fill='rgba(192,192,192,0.7)' /%3E";
    const SVG_USE_WRAPPER_BG: vector<u8> = b"%3Cuse href='%23wrapper' /%3E";
    // set_svg_text_color
    const SVG_END: vector<u8> = b"%3C/svg%3E";
    public fun generate_svg(
        base_64_bg: vector<u8>,
        r: vector<u8>,
        g: vector<u8>,
        b: vector<u8>,
        mut spans: vector<vector<u8>>
    ): vector<u8> {
        let mut svg = SVG_PREFIX;
        if (base_64_bg.is_empty()) {
            vector::append(&mut svg, SVG_WRAPPER_BG);
        } else {
            vector::append(
                &mut svg,
                create_svg_backgroun_image(base_64_bg)
            );
        };
        vector::append(
            &mut svg,
            create_svg_mask_text(spans)
        );
        vector::append(&mut svg, SVG_MID);
        if (base_64_bg.is_empty()) {
            vector::append(&mut svg, SVG_USE_WRAPPER_BG);
        };
        vector::append(&mut svg, SVG_USE);
        vector::append(&mut svg, set_svg_text_color(r, g, b));
        vector::append(&mut svg, SVG_END);
        svg
    }


    public entry fun update_alias_display(w:&mut Wrapper,r:u64,g:u64,b:u64,base64:vector<u8>) {
        let (alias_span,_) = auto_create_svg_text_span(*w.alias().bytes(),18,60);

        w.set_image_url(string::utf8( generate_svg(
            base64,
            u64_to_bytes(r),
            u64_to_bytes(g),
            u64_to_bytes(b),
            vector[alias_span]
        )));
    }
    

    
    fun calculate_font_size(u8_length: u64, canvas_width: u64, canvas_height: u64): (u64, u64) {
        let base_size: u64 = 18;
        let min_size: u64 = 1;
        let mut size = base_size;
        let mut num_lines = 1;

        while ( size > min_size) {
            let base_u8_support = (canvas_width / size) * num_lines;
            let total_height = (size + 1) * num_lines;
            if (u8_length <= base_u8_support && total_height <= canvas_height) {
                return (size, num_lines);
            };
            size = size - 1;
            num_lines = (u8_length + (canvas_width / size) - 1) / (canvas_width / size);
        };

        size = min_size;
        num_lines = (u8_length + (canvas_width / size) - 1) / (canvas_width / size);
        (size, num_lines)
    }

   fun u64_to_bytes(value: u64): vector<u8> {
        let mut result = b"";
        let mut num = value;
        let mut final_result = b"";

        if (num == 0) {
            final_result =  b"0";
        }else{
          while (num > 0) {
              let digit = (num % 10) as u8;
              let char = digit + 48;
              result.push_back(char);
              num = num / 10;
          };

          let len = result.length();
          let mut i = 0;

          while (i < len) {
              let ch = result.swap_remove(len - i - 1);
              vector::push_back(&mut final_result, ch);
              i = i + 1;
          };
        };
      final_result
     
    }




    fun is_separator(byte: u8): bool {
        byte == 32 || byte == 10 || byte == 44 || byte == 46 
    }

    fun split_into_tokens(bytes: &vector<u8>): vector<vector<u8>> {
        let mut tokens = vector::empty<vector<u8>>();
        let mut current_token = vector::empty<u8>();

        let mut i = 0;
        let len = vector::length(bytes);

        while (i < len) {
            let byte = *vector::borrow(bytes, i);
            if (is_separator(byte)) {
                if (!vector::is_empty(&current_token)) {
                    vector::push_back(&mut tokens, current_token);
                    current_token = vector::empty();
                };
                let mut separator = vector::empty<u8>();
                vector::push_back(&mut separator, byte);
                vector::push_back(&mut tokens, separator);
            } else {
                vector::push_back(&mut current_token, byte);
            };
            i = i + 1;
        };

        if (!vector::is_empty(&current_token)) {
            vector::push_back(&mut tokens, current_token);
        };

        tokens
    }
    fun split_into_lines(bytes: vector<u8>, font_size: u64, canvas_width: u64): vector<vector<u8>> {
        use std::debug;
        let mut lines = vector::empty<vector<u8>>();
        let mut current_line = vector::empty<u8>();
        let max_chars_per_line = canvas_width / font_size;
        let min_chars_per_line = max_chars_per_line / 2; // 定义一个最小字符数阈值，用于合并短行

        let tokens = split_into_tokens(&bytes);
        let mut current_length = 0;

        let mut i = 0;
        let len = vector::length(&tokens);

        while (i < len) {
            let token = vector::borrow(&tokens, i);
            let token_length = vector::length(token);

            if (current_length + token_length > max_chars_per_line) {
                if (!vector::is_empty(&current_line)) {
                    vector::push_back(&mut lines, current_line);
                    current_line = vector::empty();
                    current_length = 0;
                }
            };

            vector::append(&mut current_line, *token);
            current_length = current_length + token_length;

            // 如果是分隔符，将其保留在当前行
            if (is_separator(*vector::borrow(token, 0))) {
                debug::print(&current_line);
                if (current_length <= max_chars_per_line && current_length > token_length) {
                    // 检查上一行是否太短，可以合并
                    if (!vector::is_empty(&lines) && current_length <= min_chars_per_line) {
                        let mut last_line = vector::pop_back(&mut lines);
                        if (vector::length(&last_line) + current_length <= max_chars_per_line) {
                            vector::append(&mut last_line, current_line);
                            current_line = last_line;
                            current_length = vector::length(&current_line);
                        } else {
                            vector::push_back(&mut lines, last_line);
                            vector::push_back(&mut lines, current_line);
                            current_line = vector::empty();
                            current_length = 0;
                        }
                    } else {
                        if (!vector::is_empty(&current_line)) {
                            vector::push_back(&mut lines, current_line);
                        };
                        current_line = vector::empty();
                        current_length = 0;
                    }
                }
            };

            i = i + 1;
        };

        if (!vector::is_empty(&current_line)) {
            vector::push_back(&mut lines, current_line);
        };

        // 移除空行
        let mut final_lines = vector::empty<vector<u8>>();
        let mut j = 0;
        let final_len = vector::length(&lines);

        while (j < final_len) {
            let line = vector::borrow(&lines, j);
            if (!vector::is_empty(line)) {
                vector::push_back(&mut final_lines, *line);
            };
            j = j + 1;
        };

        final_lines
    }


  fun next_utf8_char_len(bytes: &vector<u8>, start: u64): u64 {
        let mut len = 1;
        while (start + len <= vector::length(bytes)) {
            let sub_bytes = extract_subvector(bytes, start, len);
            if (string::try_utf8(sub_bytes).is_some()) {
                return len;
            };
            len = len + 1;
        };
        1  // Fallback for invalid UTF-8
    }

  fun extract_subvector(bytes: &vector<u8>, start: u64, len: u64): vector<u8> {
        let mut sub_bytes = vector::empty<u8>();
        let mut i = 0;
        while (i < len) {
            vector::push_back(&mut sub_bytes, *vector::borrow(bytes, start + i));
            i = i + 1;
        };
        sub_bytes
    }

   fun split_into_units(bytes: &vector<u8>): vector<vector<u8>> {
        let mut units = vector::empty<vector<u8>>();
        let mut i = 0;
        let len = vector::length(bytes);

        while (i < len) {
            let ch_len = next_utf8_char_len(bytes, i);
            let mut unit = vector::empty<u8>();
            let mut j = 0;
            while (j < ch_len) {
                vector::push_back(&mut unit, *vector::borrow(bytes, i + j));
                j = j + 1;
            };
            let x = unit;
            vector::push_back(&mut units, unit);
            i = i + ch_len;
        };
        units
    }

    
    #[test]
    fun test_default_params() {
        use std::debug;
        let x = generate_svg(
            vector::empty(),
            b"255",
            b"0",
            b"0",
            vector::empty()
        );
        let y = std::string::utf8(x);
        debug::print(&y);
    }  

    #[test]
    fun test_use_base64() {
        use std::debug;
        let x = generate_svg(
            b"data:image/svg+xml;base64,Cjxzdmcgd2lkdGg9IjU1NiIgaGVpZ2h0PSI1NDYiIHZpZXdCb3g9IjAgMCA1NTYgNTQ2IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDwhLS0gSGV4YWdvbiBzaGFwZSAtLT4KICA8cG9seWdvbiBwb2ludHM9IjM4Myw2NiAxMzEsNzkgMjYsMjgyIDE0Niw0OTAgNDAwLDQ3NSA1MDMsMjcxIiBmaWxsPSIjNjY2IiAvPgogIAogIDwhLS0gU2ltcGxpZmllZCBDb250b3VyIHBhdGhzIC0tPgogIDxwYXRoIGQ9Ik0gMTg2LDI5OCBMIDE2MSwyOTcgTCAxNjYsMzEwIEwgMTgwLDI5NyBMIDE4OSwzMDIgTCAyMDEsMzQ4IEwgMTk5LDM2NCBMIDE4OSwzNjggTCAxMzIsMzYyIEwgMTg5LDM2OCBMIDE5OSwzNjQgTCAyMDEsMzQ4IFogTSAzODQsNjcgTCAxMjksODMgTCAyNiwyODYgTCAxNDMsNDg4IEwgNDAyLDQ3MSBMIDUwMywyNzEgTCAzNjgsNDk0IEwgMTQ1LDQ4OSBMIDI2LDI4NiBMIDE1Nyw2MiBMIDM4Miw2NiBMIDUwMiwyNjkgWiAiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2NjYyIgc3Ryb2tlLXdpZHRoPSIyIiAvPgo8L3N2Zz4K",
            b"255",
            b"0",
            b"0",
            vector::empty()
        );
        let y = std::string::utf8(x);
        debug::print(&y);
    }



    #[test]
    fun test_use_span() {
        use std::debug;
        let span1 = create_svg_text_span(b"这是标题",b"",b"18");
        let span2 = create_svg_text_span(b"this mid",b"",b"50");

        let x = generate_svg(
            b"data:image/svg+xml;base64,Cjxzdmcgd2lkdGg9IjU1NiIgaGVpZ2h0PSI1NDYiIHZpZXdCb3g9IjAgMCA1NTYgNTQ2IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDwhLS0gSGV4YWdvbiBzaGFwZSAtLT4KICA8cG9seWdvbiBwb2ludHM9IjM4Myw2NiAxMzEsNzkgMjYsMjgyIDE0Niw0OTAgNDAwLDQ3NSA1MDMsMjcxIiBmaWxsPSIjNjY2IiAvPgogIAogIDwhLS0gU2ltcGxpZmllZCBDb250b3VyIHBhdGhzIC0tPgogIDxwYXRoIGQ9Ik0gMTg2LDI5OCBMIDE2MSwyOTcgTCAxNjYsMzEwIEwgMTgwLDI5NyBMIDE4OSwzMDIgTCAyMDEsMzQ4IEwgMTk5LDM2NCBMIDE4OSwzNjggTCAxMzIsMzYyIEwgMTg5LDM2OCBMIDE5OSwzNjQgTCAyMDEsMzQ4IFogTSAzODQsNjcgTCAxMjksODMgTCAyNiwyODYgTCAxNDMsNDg4IEwgNDAyLDQ3MSBMIDUwMywyNzEgTCAzNjgsNDk0IEwgMTQ1LDQ4OSBMIDI2LDI4NiBMIDE1Nyw2MiBMIDM4Miw2NiBMIDUwMiwyNjkgWiAiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2NjYyIgc3Ryb2tlLXdpZHRoPSIyIiAvPgo8L3N2Zz4K",
            b"255",
            b"0",
            b"0",
            vector[span1,span2]
        );
        let y = std::string::utf8(x);
        debug::print(&y);
    }

    #[test]
    fun test_use_span_2() {
        use std::debug;
        let (span1,y_position) = auto_create_svg_text_span(b"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus lacinia odio vitae vestibulum vestibulum. Cras venenatis euismod malesuada. 这是一个中文句子，用于测试混合文本。Praesent fermentum sapien sit amet malesuada commodo. 继续添加中文，以便更好地测试。Nullam dapibus, elit vel facilisis sagittis, mi neque vehicula urna, a ultrices ex risus id ligula. 这段文字包含了中英文混合，旨在测试字符和字节长度。Etiam vehicula urna sed orci consectetur, non hendrerit lorem consectetur. 中文字符和英文字符的混合使用可以帮助我们进行更全面的测试。Curabitur ut diam nec arcu convallis commodo. Proin lacinia nunc et turpis aliquet, ac elementum leo viverra. 这是最后一部分中文，确保测试数据足够长。",18,60);
        let span2 = create_svg_text_span(b"this mid",b"18",u64_to_bytes(y_position*100/120));

        let x = generate_svg(
            b"data:image/svg+xml;base64,Cjxzdmcgd2lkdGg9IjU1NiIgaGVpZ2h0PSI1NDYiIHZpZXdCb3g9IjAgMCA1NTYgNTQ2IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDwhLS0gSGV4YWdvbiBzaGFwZSAtLT4KICA8cG9seWdvbiBwb2ludHM9IjM4Myw2NiAxMzEsNzkgMjYsMjgyIDE0Niw0OTAgNDAwLDQ3NSA1MDMsMjcxIiBmaWxsPSIjNjY2IiAvPgogIAogIDwhLS0gU2ltcGxpZmllZCBDb250b3VyIHBhdGhzIC0tPgogIDxwYXRoIGQ9Ik0gMTg2LDI5OCBMIDE2MSwyOTcgTCAxNjYsMzEwIEwgMTgwLDI5NyBMIDE4OSwzMDIgTCAyMDEsMzQ4IEwgMTk5LDM2NCBMIDE4OSwzNjggTCAxMzIsMzYyIEwgMTg5LDM2OCBMIDE5OSwzNjQgTCAyMDEsMzQ4IFogTSAzODQsNjcgTCAxMjksODMgTCAyNiwyODYgTCAxNDMsNDg4IEwgNDAyLDQ3MSBMIDUwMywyNzEgTCAzNjgsNDk0IEwgMTQ1LDQ4OSBMIDI2LDI4NiBMIDE1Nyw2MiBMIDM4Miw2NiBMIDUwMiwyNjkgWiAiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2NjYyIgc3Ryb2tlLXdpZHRoPSIyIiAvPgo8L3N2Zz4K",
            b"255",
            b"0",
            b"0",
            vector[span1,span2]
        );
        let y = std::string::utf8(x);
        debug::print(&y);
    }

    #[test]
    fun test_calculate_font_size(){
      use std::debug;
      let x = b"Cras venenatis euismod malesuada. 这是一个中文句子，用于测试混合文本。";
      let (f,y) = calculate_font_size(x.length(),120,120);
      debug::print(&f);
      debug::print(&y);


      let mut xx = split_into_lines(x, f, 120);
      while (xx.length()>0){
        debug::print(&string::utf8(xx.remove(0)));
      }
      
    }
}
