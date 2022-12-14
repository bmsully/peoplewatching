import numpy as np
import matplotlib.pyplot as plt
import matplotlib
from keras.models import Sequential
from keras.layers import Dense, Activation, Dropout, Conv2D, Flatten
from keras.optimizers import SGD
import sys

np.set_printoptions(threshold=sys.maxsize)

# Create images with random rectangles and bounding boxes. 
# num_imgs = 50000
num_imgs = 500000
qrt_num_imgs = int(num_imgs/4)
num_epochs = 25

# img_size = 8
img_width = 24
img_height = 32
object_size = 7
edge_to_center = 3
min_object_size = 5
max_object_size = 7
num_objects = 1

centers = np.zeros((num_imgs, num_objects, 2)) # top left of box
imgs = np.zeros((num_imgs, img_width, img_height, 1))  # set background to 0

print('creating images')

for i_img in range(num_imgs):
    for i_object in range(num_objects):
        w= np.random.randint(min_object_size, max_object_size)
        h = w
        x = np.random.randint(0, img_width - w)
        y = np.random.randint(0, img_height - h)
        imgs[i_img, x:x+w, y:y+h, 0] = 1.  # set rectangle to 1
        centers[i_img, i_object] = [x+w/2, y+h/2]
        
print(imgs.shape, centers.shape)
print('plotting examples')

# 
# for i in range(5):
#     plt.imshow(imgs[i].T[0], cmap='Greys', interpolation='none', origin='lower', extent=[0, img_width, 0, img_height])
#     for center in centers[i]:
#         plt.gca().add_patch(matplotlib.patches.Rectangle((center[0]-edge_to_center, center[1]-edge_to_center), object_size, object_size, ec='r', fc='none'))

plt.figure(figsize=(12, 3))
for i_subplot in range(1, 5):
    plt.subplot(1, 7, i_subplot)
    i = i_subplot
    plt.imshow(imgs[i].T[0], cmap='Greys', interpolation='none', origin='lower', extent=[0, img_width, 0, img_height])
    print('')
    for center in centers[i]:
        plt.gca().add_patch(matplotlib.patches.Rectangle((center[0]-edge_to_center, center[1]-edge_to_center), object_size, object_size, ec='r', fc='none'))

print('normalizing image data')

# Reshape and normalize the image data to mean 0 and std 1. 
x_mean = np.mean(imgs)
x_std = np.std(imgs)
X = np.empty((num_imgs, img_width, img_height, 1))
X[0:qrt_num_imgs] = (imgs[0:qrt_num_imgs] - x_mean) / x_std
print('..1..')
X[qrt_num_imgs:qrt_num_imgs*2] = (imgs[qrt_num_imgs:qrt_num_imgs*2] - x_mean) / x_std
print('..2..')
X[qrt_num_imgs*2:qrt_num_imgs*3] = (imgs[qrt_num_imgs*2:qrt_num_imgs*3] - x_mean) / x_std
print('..3..')
X[qrt_num_imgs*3:num_imgs] = (imgs[qrt_num_imgs*3:num_imgs] - x_mean) / x_std
print('..4..')



print('normalizing output data')

# Normalize x, y, w, h by img_size, so that all values are between 0 and 1.
# Important: Do not shift to negative values (e.g. by setting to mean 0), because the IOU calculation needs positive w and h.

y = centers.reshape(num_imgs, -1) / img_height
print(y.shape, np.mean(y), np.std(y))


# Split training and test.
i = int(0.8 * num_imgs)
train_X = X[:i]
test_X = X[i:]
train_y = y[:i]
test_y = y[i:]
test_imgs = imgs[i:]
test_centers = centers[i:]

print('building model')

# Build the model.
input_shape = (4, img_width, img_height, 1)
model = Sequential([
        Conv2D(1, 9, input_shape=input_shape[1:], padding="same", activation='relu'),
        Conv2D(1, 7, padding="same", activation='relu'), 
        Flatten(), 
        Dropout(0.2), 
        Dense(y.shape[-1])
    ])
model.compile('adadelta', 'mse')

print('training')

model.fit(train_X, train_y, epochs=num_epochs, validation_data=(test_X, test_y), verbose=2)

print('making bounding boxes')

# Predict bounding boxes on the test images.
pred_y = model.predict(test_X)
y_len = len(pred_y)
qrt_y_len = int(y_len/4)
pred_centers = np.empty((y_len,2))
pred_centers[0:qrt_y_len] = pred_y[0:qrt_y_len] * img_height
print('..1..')
pred_centers[qrt_y_len:qrt_y_len*2] = pred_y[qrt_y_len:qrt_y_len*2] * img_height
print('..2..')
pred_centers[qrt_y_len*2:qrt_y_len*3] = pred_y[qrt_y_len*2:qrt_y_len*3] * img_height
print('..3..')
pred_centers[qrt_y_len*3:y_len] = pred_y[qrt_y_len*3:y_len] * img_height
print('..4..')
# pred_centers = pred_y * img_height
pred_centers = pred_centers.reshape(len(pred_centers), num_objects, -1)


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

def euclidean_dis_sqrd(center1, center2):
    return (center1[0]-center2[0])**2 + (center1[1]-center2[1])**2


# Calculate the mean IOU (overlap) between the predicted and expected bounding boxes on the test dataset. 
# summed_IOU = 0.
# for pred_bbox, test_bbox in zip(pred_centers.reshape(-1, 4), test_centers.reshape(-1, 4)):
#     summed_IOU += IOU(pred_bbox, test_bbox)
# mean_IOU = summed_IOU / len(pred_centers)
# print(mean_IOU)

print('calculating mean euclidean distance')

summed_euc_dis_sqrd = 0.
for pred_cen, test_cen in zip(pred_centers.reshape(-1, 4), test_centers.reshape(-1, 4)):
    summed_euc_dis_sqrd += euclidean_dis_sqrd(pred_cen, test_cen)
mean_eds = summed_euc_dis_sqrd / len(pred_centers)
print("Mean Euclidean Distance Squared", mean_eds)

# for layer in model.layers:
#     print(layer.name)
#     print(layer.get_weights())

# print(model.get_weights())

print('saving weights in text file')

f = open('weights_19_17.txt', 'a')
f.write(str(model.get_weights()))
f.close()

print('printing summary')
model.summary()


print('plotting examples of trained model')

plt.figure(figsize=(12, 3))
for i_subplot in range(1, 5):
    plt.subplot(1, 7, i_subplot)
    i = np.random.randint(len(test_imgs))
    plt.imshow(test_imgs[i].T[0], cmap='Greys', interpolation='none', origin='lower', extent=[0, img_width, 0, img_height])
    print('')
    for pred_cen, exp_cen in zip(pred_centers[i], test_centers[i]):
        plt.gca().add_patch(matplotlib.patches.Rectangle((pred_cen[0]-edge_to_center, pred_cen[1]-edge_to_center), object_size, object_size, ec='r', fc='none'))
        plt.annotate('EDS: {:.2f}'.format(euclidean_dis_sqrd(pred_cen-edge_to_center, exp_cen-edge_to_center)), (pred_cen[0], pred_cen[1]+object_size+0.2), color='r')
        # plt.annotate('IOU: {:.2f}'.format(IOU(pred_bbox, exp_bbox)), (pred_bbox[0], pred_bbox[1]+pred_bbox[3]+0.2), color='r')
plt.show()