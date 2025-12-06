import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:order_admin_panel/repositories/data_repository.dart';

// --- EVENTS ---
abstract class DataEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadDataEvent extends DataEvent {
  final String query; // Search text
  LoadDataEvent({this.query = ''});
}

class UploadFileEvent extends DataEvent {
  final List<int> fileBytes;
  final String fileName;
  UploadFileEvent(this.fileBytes, this.fileName);
}

// --- STATES ---
abstract class DataState extends Equatable {
  @override
  List<Object> get props => [];
}

class DataInitial extends DataState {}
class DataLoading extends DataState {}

class DataLoaded extends DataState {
  final List<dynamic> orders;
  DataLoaded(this.orders);
}

class DataError extends DataState {
  final String message;
  DataError(this.message);
}

class UploadSuccess extends DataState {
  final String message;
  UploadSuccess(this.message);
}

// --- BLOC ---
class DataBloc extends Bloc<DataEvent, DataState> {
  final DataRepository dataRepository;

  DataBloc({required this.dataRepository}) : super(DataInitial()) {

    // 1. Handle Fetching Data
    on<LoadDataEvent>((event, emit) async {
      emit(DataLoading());
      try {
        final data = await dataRepository.getOrders(event.query);
        emit(DataLoaded(data));
      } catch (e) {
        emit(DataError(e.toString()));
      }
    });

    // 2. Handle File Upload
    on<UploadFileEvent>((event, emit) async {
      emit(DataLoading());
      try {
        final result = await dataRepository.uploadCsv(event.fileBytes, event.fileName);

        if (result['status'] == 'success') {
          emit(UploadSuccess("File uploaded successfully"));
          // Immediately reload data to show the new rows
          add(LoadDataEvent());
        } else {
          emit(DataError(result['message'] ?? "Upload failed"));
        }
      } catch (e) {
        emit(DataError(e.toString()));
      }
    });
  }
}