function result = main()
  img = imread('RandomDisks-P10.jpg');
  img = img_to_binary(img, 0);

  % STEP 1: filter noise
  struct_elm_noise = make_struct_elm(false, 3, 3, -1, -1);
  img = opening(img, struct_elm_noise);
  img = closing(img, struct_elm_noise);
  imshow(img);

  % STEP 2: filter middle-sized circles
  % struct_elm_a = make_struct_elm(false, 10, 10, -1, -1);
  % struct_elm_b = make_struct_elm(true, 10, 10, 20, 20);
end

function img_to_binary(img)
  [row, col] = size(img);
  for y = 1: row
    for x = 1: col
      if img(y, x) > 0
        img(y, x) = 1;
      end
    end
  end
end

function result = make_struct_elm(hollow, row_in, col_in, row_out, col_out)
  if (hollow) 
    result = zero(row_out, col_out);
    result(1:row_out, 1:col_out) = 1;
    offset_y = (row_out - row_in) / 2;
    offset_x = (col_out - col_in) / 2;
    result(offset_y:(offset_y+row_in),offset_x:(offset_x+col_in)) = 0;
  else
    result = zero(row_in, col_in);
    result(1:row_in, 1:col_in) = 1;
  end
end

function result = opening(input_img, struct_elm)
  struct_elm_sym = symmetry(struct_elm);
  result = dilation(erosion(input_img, struct_elm_sym), struct_elm);
end

function result = closing(input_img, struct_elm)
  struct_elm_sym = symmetry(struct_elm);
  result = erosion(dilation(input_img, struct_elm_sym), struct_elm);
end

function result = erosion(input_img, struct_elm)
  input_img = symmetry(input_img);
  result = minkowski_op('subtraction', input_img, struct_elm);
end

function result = dilation(input_img, struct_elm)
  input_img = symmetry(input_img);
  result = minkowski_op('addition', input_img, struct_elm);
end

function result = symmetry(input_object)
  %TODO no need for this project, to be implemented in future for integrity
  result = input_object;
end

function result = minkowski_op(operation, input_img, struct_elm)
  [struct_h, struct_w] = size(struct_elm);
  [img_rows, img_cols] = size(input_img);
  struct_w_half = floor(struct_w / 2);
  struct_h_half = floor(struct_h / 2);
  dia_out = zeros(img_rows + 2*struct_h_half , img_cols + 2*struct_w_half);
  input_img_padded = [
    zeros(struct_h_half, img_cols + 2*struct_w_half);  % top part
    zeros(img_rows, struct_w_half) input_img zeros(img_rows, struct_w_half);  % mid part
    zeros(struct_h_half, img_cols + 2*struct_w_half) % bottom part
  ];

  %{explanation of offset: Know that when looping through each pixel in the image, the x and y can be either odd of even. Also know that struct_w_half and struct_h_half are floored, so if x or y is even, either/both of struct_w_half and struct_h_half need to - 1. The offset variable is to solve this problem. It is a 3d array. The first dimension represents whether x is even, second represents whether y is even, and third represents the offset of x or y (0 or -1)%}
  offset = [-1 -1; 0 -1];
  offset(:, :, 2) = [-1 0; 0 0];

  for col = (struct_w_half+1) : img_cols
    % x1, x2, y1, y2 defines the boundary of the struct element inside the output padded image
    x1 = col - struct_w_half;
    x2 = col + struct_w_half;
    for row = (struct_w_half+1): img_rows
      y1 = row - struct_h_half;
      y2 = row + struct_h_half;

      if(input_img_padded(row,col) ~= 1)
        continue;
      end

      y_offset = offset(rem(struct_w, 2)+1, rem(struct_h, 2)+1, 1);
      x_offset = offset(rem(struct_w, 2)+1, rem(struct_h, 2)+1, 2);
      mask = (input_img_padded(y1 : y2+y_offset, x1 : x2+x_offset)) & struct_elm;

      if (operation == 'subtraction' && isequal(mask, struct_elm))
        dia_out(row, col) = dia_out(row, col)|struct_elm(struct_h_half+1, struct_w_half+1);
      elseif (operation == 'addition' && any(mask(:) == 1))
        dia_out(row, col) = 1;  %TODO I am not sure
      end
    end
  end
  result = dia_out(struct_w_half+1:img_rows, struct_h_half+1:img_cols);
end
