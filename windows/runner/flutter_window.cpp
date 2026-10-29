#include "flutter_window.h"

#include <optional>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <mmsystem.h>
#include <string>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  recorder_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "daymark/recorder",
      &flutter::StandardMethodCodec::GetInstance());
  recorder_->SetMethodCallHandler([](const auto& call, auto result) {
    const std::string method = call.method_name();
    if (method == "start") {
      MCIERROR err = mciSendStringW(L"open new type waveaudio alias daymark_rec", nullptr, 0, nullptr);
      if (!err) err = mciSendStringW(L"set daymark_rec time format ms", nullptr, 0, nullptr);
      if (!err) err = mciSendStringW(L"set daymark_rec format tag pcm samplespersec 16000 bitspersample 16 channels 1", nullptr, 0, nullptr);
      if (!err) err = mciSendStringW(L"record daymark_rec", nullptr, 0, nullptr);
      if (err) {
        mciSendStringW(L"close daymark_rec", nullptr, 0, nullptr);
        result->Error("recording_failed", "Mikrofonaufnahme konnte nicht gestartet werden.");
      } else result->Success();
    } else if (method == "stop") {
      const auto* path = std::get_if<std::string>(call.arguments());
      if (!path) { result->Error("invalid_path", "Dateipfad fehlt."); return; }
      int len = MultiByteToWideChar(CP_UTF8, 0, path->c_str(), -1, nullptr, 0);
      std::wstring wide(len, L'\0');
      MultiByteToWideChar(CP_UTF8, 0, path->c_str(), -1, wide.data(), len);
      mciSendStringW(L"stop daymark_rec", nullptr, 0, nullptr);
      wide.pop_back();
      std::wstring command = L"save daymark_rec \"" + wide + L"\"";
      MCIERROR err = mciSendStringW(command.c_str(), nullptr, 0, nullptr);
      mciSendStringW(L"close daymark_rec", nullptr, 0, nullptr);
      if (err) result->Error("save_failed", "Aufnahme konnte nicht gespeichert werden.");
      else result->Success();
    } else if (method == "cancel") {
      mciSendStringW(L"stop daymark_rec", nullptr, 0, nullptr);
      mciSendStringW(L"close daymark_rec", nullptr, 0, nullptr);
      result->Success();
    } else result->NotImplemented();
  });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    recorder_ = nullptr;
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
