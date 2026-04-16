import os
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import matplotlib.pyplot as plt

# ── Paths ────────────────────────────────────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(BASE_DIR, "FaceShape Dataset")
TRAIN_DIR = os.path.join(DATASET_DIR, "training_set")
TEST_DIR = os.path.join(DATASET_DIR, "testing_set")
MODEL_OUTPUT = os.path.join(BASE_DIR, "face_shape_model.keras")

# ── Config ───────────────────────────────────────────────────────────────────
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 15
CLASSES = ["Heart", "Oblong", "Oval", "Round", "Square"]

# ── Data augmentation for training ───────────────────────────────────────────
train_datagen = ImageDataGenerator(
    rescale=1.0 / 255,
    rotation_range=15,
    width_shift_range=0.1,
    height_shift_range=0.1,
    horizontal_flip=True,
    zoom_range=0.1,
)

test_datagen = ImageDataGenerator(rescale=1.0 / 255)

train_gen = train_datagen.flow_from_directory(
    TRAIN_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode="categorical",
    shuffle=True,
)

test_gen = test_datagen.flow_from_directory(
    TEST_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode="categorical",
    shuffle=False,
)

print(f"\nClass indices: {train_gen.class_indices}")
print(f"Training samples: {train_gen.samples}")
print(f"Testing samples:  {test_gen.samples}\n")

# ── Model: MobileNetV2 transfer learning ─────────────────────────────────────
base_model = MobileNetV2(
    input_shape=(*IMG_SIZE, 3),
    include_top=False,
    weights="imagenet",
)
base_model.trainable = False  # freeze pretrained layers

model = models.Sequential([
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.Dense(128, activation="relu"),
    layers.Dropout(0.3),
    layers.Dense(len(CLASSES), activation="softmax"),
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
    loss="categorical_crossentropy",
    metrics=["accuracy"],
)

model.summary()

# ── Callbacks ────────────────────────────────────────────────────────────────
callbacks = [
    tf.keras.callbacks.EarlyStopping(
        monitor="val_accuracy", patience=4, restore_best_weights=True
    ),
    tf.keras.callbacks.ReduceLROnPlateau(
        monitor="val_loss", factor=0.5, patience=2, verbose=1
    ),
]

# ── Phase 1: Train top layers ─────────────────────────────────────────────────
print("\n── Phase 1: Training top layers ──")
history1 = model.fit(
    train_gen,
    epochs=EPOCHS,
    validation_data=test_gen,
    callbacks=callbacks,
)

# ── Phase 2: Fine-tune last 30 layers of base model ──────────────────────────
print("\n── Phase 2: Fine-tuning ──")
base_model.trainable = True
for layer in base_model.layers[:-30]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
    loss="categorical_crossentropy",
    metrics=["accuracy"],
)

history2 = model.fit(
    train_gen,
    epochs=10,
    validation_data=test_gen,
    callbacks=callbacks,
)

# ── Evaluate ──────────────────────────────────────────────────────────────────
loss, accuracy = model.evaluate(test_gen)
print(f"\nTest accuracy: {accuracy * 100:.2f}%")
print(f"Test loss:     {loss:.4f}")

# ── Save model ────────────────────────────────────────────────────────────────
model.save(MODEL_OUTPUT)
print(f"\nModel saved to: {MODEL_OUTPUT}")

# ── Plot accuracy & loss ──────────────────────────────────────────────────────
all_acc = history1.history["accuracy"] + history2.history["accuracy"]
all_val_acc = history1.history["val_accuracy"] + history2.history["val_accuracy"]
all_loss = history1.history["loss"] + history2.history["loss"]
all_val_loss = history1.history["val_loss"] + history2.history["val_loss"]

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))

ax1.plot(all_acc, label="Train")
ax1.plot(all_val_acc, label="Validation")
ax1.set_title("Accuracy")
ax1.set_xlabel("Epoch")
ax1.legend()

ax2.plot(all_loss, label="Train")
ax2.plot(all_val_loss, label="Validation")
ax2.set_title("Loss")
ax2.set_xlabel("Epoch")
ax2.legend()

plt.tight_layout()
plot_path = os.path.join(BASE_DIR, "training_results.png")
plt.savefig(plot_path)
print(f"Training chart saved to: {plot_path}")
