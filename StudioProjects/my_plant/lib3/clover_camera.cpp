#include "clover_camera.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <memory>
#include <opencv2/opencv.hpp>

namespace {
class CloverCamera {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  CloverCamera();

  virtual ~CloverCamera();

 private:
  void StartCamera(const flutter::MethodCall<> &method_call,
                   std::unique_ptr<flutter::MethodResult<>> result);

  std::unique_ptr<flutter::MethodChannel<>> channel_;
};

void CloverCamera::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<>>(
      registrar->messenger(), "clover_camera",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<CloverCamera>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const flutter::MethodCall<> &call,
                                      std::unique_ptr<flutter::MethodResult<>> result) {
        plugin_pointer->StartCamera(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

CloverCamera::CloverCamera() {}

CloverCamera::~CloverCamera() {}

void CloverCamera::StartCamera(const flutter::MethodCall<> &method_call,
                               std::unique_ptr<flutter::MethodResult<>> result) {
  cv::VideoCapture cap(0);  // Open the default camera
  if (!cap.isOpened()) {
    result->Error("CAMERA_ERROR", "Failed to open camera.");
    return;
  }

  cv::Mat frame;
  cap >> frame;  // Capture a frame
  if (frame.empty()) {
    result->Error("CAMERA_ERROR", "Failed to capture frame.");
    return;
  }

  // Convert frame to grayscale
  cv::cvtColor(frame, frame, cv::COLOR_BGR2GRAY);

  // Encode the frame as a JPEG image
  std::vector<uchar> buf;
  cv::imencode(".jpg", frame, buf);

  // Return the image as a base64 encoded string
  std::string encoded = "data:image/jpeg;base64," + cv::base64::encode(buf.data(), buf.size());
  result->Success(encoded);
}

}  // namespace

void CloverCameraRegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  CloverCamera::RegisterWithRegistrar(registrar);
}
