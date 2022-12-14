import numpy as np
import matplotlib.pyplot as plt
import matplotlib
from keras.models import Sequential
from keras.layers import Dense, Activation, Dropout, Conv2D, Flatten, MaxPooling2D
from keras.optimizers import SGD

# Create images with random rectangles and bounding boxes. 
# num_imgs = 50000
num_imgs = 500000
num_epochs = 20

# img_size = 8
img_width = 8
img_height = 8
min_object_size = 2
max_object_size = 3
num_objects = 1

bboxes = np.zeros((num_imgs, num_objects, 4)) # dimensions of boxes [top left corner x, top left corner y, width, height]
imgs = np.zeros((num_imgs, img_width, img_height, 1))  # set background to 0

for i_img in range(num_imgs):
    for i_object in range(num_objects):
        w, h = np.random.randint(min_object_size, max_object_size, size=2)
        x = np.random.randint(0, img_width - w)
        y = np.random.randint(0, img_height - h)
        imgs[i_img, x:x+w, y:y+h, 0] = 1.  # set rectangle to 1
        bboxes[i_img, i_object] = [x, y, w, h]
        
print(imgs.shape, bboxes.shape)

# 
i = 0
plt.imshow(imgs[i].T[0], cmap='Greys', interpolation='none', origin='lower', extent=[0, img_width, 0, img_height])
for bbox in bboxes[i]:
    plt.gca().add_patch(matplotlib.patches.Rectangle((bbox[0], bbox[1]), bbox[2], bbox[3], ec='r', fc='none'))
# plt.show()

# Reshape and normalize the image data to mean 0 and std 1. 
X = (imgs - np.mean(imgs)) / np.std(imgs)
print(X.shape, np.mean(X), np.std(X))

# Normalize x, y, w, h by img_size, so that all values are between 0 and 1.
# Important: Do not shift to negative values (e.g. by setting to mean 0), because the IOU calculation needs positive w and h.
y = bboxes.reshape(num_imgs, -1) / img_height
print(y.shape, np.mean(y), np.std(y))

# Split training and test.
i = int(0.8 * num_imgs)
train_X = X[:i]
test_X = X[i:]
train_y = y[:i]
test_y = y[i:]
test_imgs = imgs[i:]
test_bboxes = bboxes[i:]

# Build the model.
input_shape = (4, img_width, img_height, 1)
model = Sequential([
        Conv2D(8, 5, input_shape=input_shape[1:], activation='relu'), 
        # MaxPooling2D(pool_size=(4, 4)), 
        Flatten(), 
        Dropout(0.2), 
        Dense(y.shape[-1])
    ])
model.compile('adadelta', 'mse')

model.fit(train_X, train_y, epochs=num_epochs, validation_data=(test_X, test_y), verbose=2)

# Predict bounding boxes on the test images.
pred_y = model.predict(test_X)
pred_bboxes = pred_y * img_height
pred_bboxes = pred_bboxes.reshape(len(pred_bboxes), num_objects, -1)
print(pred_bboxes.shape)


def IOU(bbox1, bbox2):
    '''Calculate overlap between two bounding boxes [x, y, w, h] as the area of intersection over the area of unity'''
    x1, y1, w1, h1 = bbox1[0], bbox1[1], bbox1[2], bbox1[3]
    x2, y2, w2, h2 = bbox2[0], bbox2[1], bbox2[2], bbox2[3]

    w_I = min(x1 + w1, x2 + w2) - max(x1, x2)
    h_I = min(y1 + h1, y2 + h2) - max(y1, y2)
    if w_I <= 0 or h_I <= 0:  # no overlap
        return 0.
    I = w_I * h_I

    U = w1 * h1 + w2 * h2 - I

    return I / U

plt.figure(figsize=(12, 3))
for i_subplot in range(1, 5):
    plt.subplot(1, 4, i_subplot)
    i = np.random.randint(len(test_imgs))
    plt.imshow(test_imgs[i].T[0], cmap='Greys', interpolation='none', origin='lower', extent=[0, img_width, 0, img_height])
    for pred_bbox, exp_bbox in zip(pred_bboxes[i], test_bboxes[i]):
        plt.gca().add_patch(matplotlib.patches.Rectangle((pred_bbox[0], pred_bbox[1]), pred_bbox[2], pred_bbox[3], ec='r', fc='none'))
        plt.annotate('IOU: {:.2f}'.format(IOU(pred_bbox, exp_bbox)), (pred_bbox[0], pred_bbox[1]+pred_bbox[3]+0.2), color='r')
plt.show()

# Calculate the mean IOU (overlap) between the predicted and expected bounding boxes on the test dataset. 
summed_IOU = 0.
for pred_bbox, test_bbox in zip(pred_bboxes.reshape(-1, 4), test_bboxes.reshape(-1, 4)):
    summed_IOU += IOU(pred_bbox, test_bbox)
mean_IOU = summed_IOU / len(pred_bboxes)
print(mean_IOU)

# weights_array = model.get_weights()
# for weights_list in weights_array:
#     for weights in weights_list:
#         print(weights)
#     print()
# print("boo you whore")
# print(weights_array)
# with open('readme.txt', 'w') as f:
#     f.write(weights_array)

for layer in model.layers:
    print(layer.name)
    print(layer.get_weights())
