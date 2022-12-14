import numpy as np

f = open("weights_19_17_2.txt", "r")
weights_str = f.read()
f.close()

weights_str = weights_str.replace(" ", "")
weights_str = weights_str.replace("\n", "")

weights_array = weights_str.split('***')

# # conv 9
# print('conv9')
# conv9_str = weights_array[0].replace("[", "")
# conv9_str = conv9_str.replace("]", "")
# conv9_list_str = conv9_str.split(',')
# conv9_list = []
# for weight in conv9_list_str:
#     weight_int = int(float(weight) * 2**17)
#     if (weight_int < 0):
#         weight_bin = bin(0b100000000000000000 + abs(weight_int))
#         weight_bin = weight_bin[2:]
#     else:
#         weight_bin = bin(weight_int)
#         weight_bin = weight_bin[2:].zfill(18)

#     conv9_list.append(weight_bin)


# print(conv9_list_str)
# print(conv9_list)

# f = open("conv9.mem", "w")
# for i in range(9):
#     for j in range(9):
#         f.write(conv9_list[j+i*9])
#     f.write('\n')
# f.close()

# # conv 9 bias
# print('conv9 bias')
# conv9_bias_str = weights_array[1]
# print(conv9_bias_str)

# print('conv7')
# conv9_str = weights_array[2].replace("[", "")
# conv9_str = conv9_str.replace("]", "")
# conv9_list_str = conv9_str.split(',')
# conv9_list = []
# for weight in conv9_list_str:
#     weight_int = int(float(weight) * 2**17)
#     if (weight_int < 0):
#         weight_bin = bin(0b100000000000000000 + abs(weight_int))
#         weight_bin = weight_bin[2:]
#     else:
#         weight_bin = bin(weight_int)
#         weight_bin = weight_bin[2:].zfill(18)

#     conv9_list.append(weight_bin)


# print(conv9_list_str)
# print(conv9_list)

# f = open("conv7.mem", "w")
# for i in range(7):
#     for j in range(7):
#         f.write(conv9_list[j+i*7])
#     f.write('\n')
# f.close()

# # conv 9 bias
# print('conv7 bias')
# conv7_bias_str = weights_array[3]
# print(conv7_bias_str)

print('dense')
conv9_str = weights_array[4].replace("[", "")
conv9_str = conv9_str.replace("]", "")
conv9_list_str = conv9_str.split(',')
conv9_list = []
for weight in conv9_list_str:
    weight_int = int(float(weight) * 2**17)
    if (weight_int < 0):
        weight_bin = bin(0b100000000000000000 + abs(weight_int))
        weight_bin = weight_bin[2:]
    else:
        weight_bin = bin(weight_int)
        weight_bin = weight_bin[2:].zfill(18)

    conv9_list.append(weight_bin)


print(conv9_list_str)
print(conv9_list)

f = open("dense.mem", "w")
for i in range(24):
    for j in range(32):
        f.write(conv9_list[j+i*24])
    f.write('\n')
f.close()

